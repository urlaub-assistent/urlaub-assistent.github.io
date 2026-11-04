const ALLOWED_ORIGINS = new Set(["https://urlaub-assistent.github.io","https://liveos.github.io","https://urlaub-assistent.netlify.app"]);
const rateState = new Map<string,{start:number;count:number}>();
const WINDOW_MS = 5 * 60 * 1000;
function corsHeaders(origin:string){return {
  "Access-Control-Allow-Origin":ALLOWED_ORIGINS.has(origin)?origin:"null",
  "Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods":"POST, OPTIONS","Vary":"Origin"
};}
function reply(body:unknown,status:number,origin:string){
  return new Response(JSON.stringify(body),{status,headers:{...corsHeaders(origin),"Content-Type":"application/json; charset=utf-8","Cache-Control":"no-store"}});
}
function decodeEntities(value:string){
  return value.replace(/&amp;/gi,"&").replace(/&quot;/gi,'"').replace(/&#39;/gi,"'").replace(/&apos;/gi,"'").replace(/&lt;/gi,"<").replace(/&gt;/gi,">")
    .replace(/&#(\d+);/g,(_m,n)=>String.fromCodePoint(Math.min(0x10ffff,Number(n)||0)))
    .replace(/&#x([0-9a-f]+);/gi,(_m,n)=>String.fromCodePoint(Math.min(0x10ffff,parseInt(n,16)||0)));
}
function stripTags(value:string){
  return decodeEntities(value.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi," ").replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi," ").replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi," ").replace(/<svg\b[^>]*>[\s\S]*?<\/svg>/gi," ").replace(/<[^>]+>/g," ")).replace(/\s+/g," ").trim();
}
function safePublicUrl(value:string){
  let u:URL;try{u=new URL(value);}catch{return false;}
  if(u.protocol!=="http:"&&u.protocol!=="https:")return false;
  if(u.username||u.password)return false;
  const h=u.hostname.toLowerCase().replace(/^\[|\]$/g,"");
  if(!h||h==="localhost"||h.endsWith(".localhost")||h.endsWith(".local")||h.endsWith(".internal"))return false;
  if(/^(127\.|10\.|192\.168\.|169\.254\.|0\.|224\.|240\.)/.test(h)||/^172\.(1[6-9]|2\d|3[01])\./.test(h))return false;
  if(h==="::1"||h.startsWith("fe80:")||h.startsWith("fc")||h.startsWith("fd"))return false;
  return true;
}
async function fetchText(url:string,maxBytes=650000){
  let current=url;
  for(let hop=0;hop<4;hop++){
    if(!safePublicUrl(current))throw new Error("Diese Adresse ist nicht als öffentliche Webseite zugelassen.");
    const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),8500);
    let response:Response;
    try{response=await fetch(current,{redirect:"manual",signal:controller.signal,headers:{"User-Agent":"LiveOS-WebResearch/1.0","Accept":"text/html,application/xhtml+xml,text/plain;q=0.8,*/*;q=0.2"}});}
    finally{clearTimeout(timer);}
    if([301,302,303,307,308].includes(response.status)){const location=response.headers.get("location");if(!location)throw new Error("Ungültige Weiterleitung.");current=new URL(location,current).toString();continue;}
    if(!response.ok)throw new Error("Die Webseite antwortet mit HTTP "+response.status+".");
    const type=(response.headers.get("content-type")||"").toLowerCase();
    if(!(type.includes("text/html")||type.includes("application/xhtml")||type.includes("text/plain")||type.includes("xml")||type.includes("vtt")))throw new Error("Diese URL liefert keinen lesbaren HTML- oder Textinhalt.");
    const reader=response.body?.getReader();if(!reader)throw new Error("Kein lesbarer Seiteninhalt.");
    const chunks:Uint8Array[]=[];let size=0;
    while(true){const part=await reader.read();if(part.done)break;size+=part.value.byteLength;if(size>maxBytes){await reader.cancel();break;}chunks.push(part.value);}
    const joined=new Uint8Array(size);let offset=0;for(const chunk of chunks){joined.set(chunk,offset);offset+=chunk.byteLength;}
    return {html:new TextDecoder("utf-8",{fatal:false}).decode(joined),url:current,type};
  }
  throw new Error("Zu viele Weiterleitungen.");
}
function meta(html:string,key:string){
  const tags=html.match(/<meta\b[^>]*>/gi)||[];
  for(const tag of tags){
    const name=(tag.match(/(?:property|name)\s*=\s*["']([^"']+)["']/i)||[])[1]||"";
    const content=(tag.match(/content\s*=\s*["']([^"']*)["']/i)||[])[1]||"";
    if(name.toLowerCase()===key.toLowerCase()&&content)return decodeEntities(content);
  }
  return "";
}
function extractPage(html:string,url:string){
  const titleMatch=html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
  const title=meta(html,"og:title")||(titleMatch?stripTags(titleMatch[1]):url);
  const description=meta(html,"og:description")||meta(html,"description");
  let main=html.match(/<main\b[^>]*>([\s\S]*?)<\/main>/i)?.[1]||html.match(/<article\b[^>]*>([\s\S]*?)<\/article>/i)?.[1]||html;
  main=main.replace(/<(nav|header|footer|aside|form|script|style|noscript|svg)\b[^>]*>[\s\S]*?<\/\1>/gi," ");
  const content=stripTags(main).slice(0,5200);
  return {title:title.slice(0,220),description:description.slice(0,600),content,snippet:(content||description).slice(0,800),url};
}
function unwrapDuckUrl(value:string){
  try{const absolute=value.startsWith("//")?"https:"+value:value;const u=new URL(absolute,"https://duckduckgo.com");const target=u.searchParams.get("uddg");return target?decodeURIComponent(target):u.toString();}catch{return value;}
}
function parseSearchResults(html:string,mode:string){
  const results:Array<{title:string;description:string;snippet:string;url:string}>=[];
  const pattern=/<a[^>]+class=["'][^"']*result__a[^"']*["'][^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi;
  let m:RegExpExecArray|null;
  while((m=pattern.exec(html))!==null&&results.length<6){
    const url=unwrapDuckUrl(decodeEntities(m[1]));if(!safePublicUrl(url))continue;
    if(mode==="youtube"&&!/youtube\.com\/(watch|shorts)/i.test(url))continue;
    const title=stripTags(m[2]).slice(0,220);if(!title)continue;
    const tail=html.slice(pattern.lastIndex,pattern.lastIndex+1800);
    const sm=tail.match(/class=["'][^"']*result__snippet[^"']*["'][^>]*>([\s\S]*?)<\/(?:a|td|div)/i);
    const description=sm?stripTags(sm[1]).slice(0,450):"";
    if(!results.some(x=>x.url===url))results.push({title,description,snippet:description,url});
  }
  return results;
}
async function youtubeDetails(item:{title:string;description:string;snippet:string;url:string}){
  try{
    const fetched=await fetchText(item.url,500000);const html=fetched.html;
    item.title=meta(html,"og:title")||item.title;item.description=meta(html,"og:description")||item.description;item.snippet=item.description||item.snippet;item.url=fetched.url;
    const caption=html.match(/"captionTracks":(\[[\s\S]*?\])\s*,\s*"audioTracks"/);
    const track=caption?.[1]?.match(/"baseUrl":"((?:\\.|[^"\\])*)"/);
    if(track?.[1]){
      const captionUrl=track[1].replace(/\\u0026/g,"&").replace(/\\u003d/g,"=").replace(/\\\//g,"/");
      if(safePublicUrl(captionUrl)&&new URL(captionUrl).hostname.endsWith("youtube.com")){
        const subtitles=await fetchText(captionUrl,160000).catch(()=>null);
        if(subtitles){const lines=[...subtitles.html.matchAll(/<text[^>]*>([\s\S]*?)<\/text>/gi)].slice(0,80).map(x=>stripTags(x[1]));if(lines.length)(item as any).transcript=lines.join(" ").slice(0,4500);}
      }
    }
  }catch{/* Public search result is still useful when the page cannot be opened. */}
  return item;
}
Deno.serve(async(req:Request)=>{
  const origin=req.headers.get("origin")||"";
  if(req.method==="OPTIONS")return new Response("ok",{headers:corsHeaders(origin)});
  if(req.method!=="POST")return reply({error:"Method not allowed"},405,origin);
  if(!ALLOWED_ORIGINS.has(origin))return reply({error:"Origin not allowed"},403,origin);
  const ip=(req.headers.get("x-forwarded-for")||"").split(",")[0].trim()||"unknown";
  const now=Date.now();const state=rateState.get(ip)||{start:now,count:0};
  if(now-state.start>WINDOW_MS){state.start=now;state.count=0;}state.count++;rateState.set(ip,state);
  if(state.count>22)return reply({error:"Zu viele Anfragen. Bitte warte einige Minuten."},429,origin);
  try{
    const body=await req.json();
    if(body?.action==="read"){
      const url=String(body.url||"").slice(0,1800);if(!safePublicUrl(url))return reply({error:"Bitte gib eine gültige öffentliche HTTP- oder HTTPS-Webseite an."},400,origin);
      const page=await fetchText(url);const result=extractPage(page.html,page.url);
      if(new URL(page.url).hostname.endsWith("youtube.com"))return reply({action:"read",mode:"youtube",query:url,results:[await youtubeDetails(result as any)]},200,origin);
      return reply({action:"read",mode:"web",query:url,results:[result]},200,origin);
    }
    if(body?.action==="search"){
      const query=String(body.query||"").trim().slice(0,350);const mode=body.mode==="youtube"?"youtube":"web";
      if(query.length<2)return reply({error:"Bitte gib einen längeren Suchbegriff ein."},400,origin);
      const q=mode==="youtube"?"site:youtube.com/watch "+query:query;
      const page=await fetchText("https://html.duckduckgo.com/html/?q="+encodeURIComponent(q),520000);
      let results=parseSearchResults(page.html,mode);
      if(mode==="youtube")results=await Promise.all(results.slice(0,4).map(youtubeDetails));
      else results=await Promise.all(results.slice(0,3).map(async item=>{
        try{const p=await fetchText(item.url,520000);const extracted=extractPage(p.html,p.url);return {...item,...extracted,description:extracted.description||item.description,snippet:extracted.content||item.snippet};}
        catch{return item;}
      }));
      return reply({action:"search",mode,query,results},200,origin);
    }
    return reply({error:"Unbekannte Aktion."},400,origin);
  }catch(error){const message=error instanceof Error?error.message:"Webrecherche fehlgeschlagen.";return reply({error:message.slice(0,400)},502,origin);}
});