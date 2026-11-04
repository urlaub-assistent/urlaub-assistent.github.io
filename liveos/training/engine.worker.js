importScripts("./skillnet-core.js?v=3");
"use strict";
const Core=self.LiveOSSkillNet;
let model=null,dataset=null,focusLabels=null,random=null;
let running=false,lastMetricsAt=0,lastCheckpointStep=0;
let totalReward=0,totalBatchSamples=0,lastLoss=0,lastAccuracy=0;
function makeRandom(seed){
  let x=seed>>>0||1;
  return function(){x=(Math.imul(x,1664525)+1013904223)>>>0;return x/4294967296;};
}
function pickTrainingItem(){
  const useFocus=focusLabels&&focusLabels.length&&Core.FOCUS.all.length>focusLabels.length;
  let pool=dataset.train;
  if(useFocus&&random()<0.78){
    const label=focusLabels[Math.floor(random()*focusLabels.length)];
    const filtered=dataset.byLabel[label];
    if(filtered&&filtered.length)pool=filtered;
  }
  return pool[Math.floor(random()*pool.length)];
}
function sendCheckpoint(force){
  const now=Date.now();
  if(force||now-lastMetricsAt>7000){
    const validation=Core.evaluate(model,dataset.validation);
    model.bestAccuracy=Math.max(model.bestAccuracy,validation.accuracy);
    self.postMessage({
      type:"metrics",
      metrics:{
        steps:model.steps,examplesSeen:model.examplesSeen,
        trainLoss:lastLoss,trainAccuracy:lastAccuracy,
        validationAccuracy:validation.accuracy,
        validationLoss:validation.loss,
        avgReward:totalReward/Math.max(1,totalBatchSamples),
        bestAccuracy:model.bestAccuracy,
        focusKey:dataset.focusKey,
        validationCount:validation.count,
        labels:model.labels.length,
        time:Date.now()
      },
      checkpoint:Core.serialize(model),
      finalCheckpoint:!!force,
      sample:dataset.validation[Math.floor(random()*dataset.validation.length)]?.text||""
    });
    lastMetricsAt=now;
  }
}
function loop(){
  if(!running)return;
  const start=performance.now();
  let batches=0;
  while(running&&batches<3&&performance.now()-start<45){
    const batch=[];
    for(let i=0;i<24;i++)batch.push(pickTrainingItem());
    const learningRate=Math.max(0.025,0.07/(1+model.steps/5000));
    const result=Core.trainBatch(model,batch,learningRate);
    lastLoss=result.loss;
    lastAccuracy=result.accuracy;
    totalReward+=result.reward*batch.length;
    totalBatchSamples+=batch.length;
    batches++;
  }
  if(model.steps-lastCheckpointStep>=10){sendCheckpoint(false);lastCheckpointStep=model.steps;}
  if(batches>0){
    self.postMessage({
      type:"tick",
      steps:model.steps,
      examplesSeen:model.examplesSeen,
      lastLoss,lastAccuracy,
      avgReward:totalReward/Math.max(1,totalBatchSamples)
    });
  }
  setTimeout(loop,16);
}
self.onmessage=function(event){
  const message=event.data||{};
  if(message.type==="init"){
    dataset=Core.buildDataset(message.focus||"",message.curatedExamples||[]);
    dataset.byLabel={};
    dataset.train.forEach(function(row){
      (dataset.byLabel[row.label]||(dataset.byLabel[row.label]=[])).push(row);
    });
    focusLabels=dataset.focusLabels;
    model=Core.createModel(message.modelState||null);
    random=makeRandom((Date.now()^0x5bd1e995)>>>0);
    self.postMessage({
      type:"ready",
      labels:model.labels.length,
      trainCount:dataset.train.length,
      validationCount:dataset.validation.length,
      focusKey:dataset.focusKey,
      focusLabels:focusLabels,
      steps:model.steps,
      examplesSeen:model.examplesSeen,
      checkpoint:Core.serialize(model)
    });
  }else if(message.type==="start"){
    if(!model||!dataset){self.postMessage({type:"error",message:"Trainingsmodell ist noch nicht geladen."});return;}
    if(running)return;
    running=true;
    self.postMessage({type:"status",status:"running"});
    loop();
  }else if(message.type==="pause"){
    running=false;
    sendCheckpoint(true);
    self.postMessage({type:"status",status:"paused"});
  }else if(message.type==="stop"){
    running=false;
    sendCheckpoint(true);
    self.postMessage({type:"status",status:"stopped"});
  }else if(message.type==="predict"){
    if(!model){self.postMessage({type:"prediction",id:message.id,error:"Model not ready"});return;}
    self.postMessage({type:"prediction",id:message.id,result:Core.predict(model,message.text||"")});
  }
};