importScripts("./skillnet-core.js?v=4");
"use strict";
const Core = self.LiveOSSkillNet;
let model = null, dataset = null, focusLabels = null, activeFocusLabels = null, activeAllLabels = null, random = null;
let running = false, lastMetricsAt = 0, nextEvaluationStep = 120;
let totalReward = 0, totalBatchSamples = 0, lastLoss = 0, lastAccuracy = 0;
let bestCheckpoint = null, bestValidationScore = 0, bestValidationLoss = Infinity;
let staleEvaluations = 0, learningRateScale = 1, recoveryCount = 0;

function makeRandom(seed) {
  let x = seed >>> 0 || 1;
  return function () { x = (Math.imul(x, 1664525) + 1013904223) >>> 0; return x / 4294967296; };
}
function pickTrainingItem() {
  const labels = random() < 0.72 ? activeFocusLabels : activeAllLabels;
  const eligible = labels && labels.length ? labels : activeAllLabels;
  const label = eligible[Math.floor(random() * eligible.length)];
  const rows = dataset.byLabel[label] || dataset.train;
  return rows[Math.floor(random() * rows.length)];
}
function evaluateAndProtect() {
  let validation = Core.evaluate(model, dataset.validation);
  const score = Number.isFinite(validation.balancedAccuracy) ? validation.balancedAccuracy : validation.accuracy;
  const improved = !bestCheckpoint ||
    score > bestValidationScore + 0.001 ||
    (score >= bestValidationScore - 0.002 && validation.loss < bestValidationLoss - 0.004);
  if (improved) {
    bestValidationScore = score;
    bestValidationLoss = validation.loss;
    model.bestAccuracy = Math.max(model.bestAccuracy || 0, score);
    bestCheckpoint = Core.serialize(model);
    staleEvaluations = 0;
  } else {
    staleEvaluations++;
  }

  if (staleEvaluations >= 5 && bestCheckpoint) {
    const attemptedSteps = model.steps;
    const attemptedExamples = model.examplesSeen;
    model = Core.createModel(bestCheckpoint);
    model.steps = attemptedSteps;
    model.examplesSeen = attemptedExamples;
    model.bestAccuracy = Math.max(model.bestAccuracy || 0, bestValidationScore);
    learningRateScale = Math.max(0.22, learningRateScale * 0.7);
    staleEvaluations = 0;
    recoveryCount++;
    validation = Core.evaluate(model, dataset.validation);
    bestCheckpoint = Core.serialize(model);
    self.postMessage({
      type: "recovery",
      message: "Validierungsfortschritt stagnierte. OS3 ist zum besten Checkpoint zurückgekehrt und trainiert mit kleinerer Lernrate weiter.",
      learningRateScale, recoveryCount
    });
  }
  return validation;
}
function checkpointSnapshot() {
  const snapshot = bestCheckpoint ? {
    ...bestCheckpoint,
    steps: model.steps,
    examplesSeen: model.examplesSeen,
    bestAccuracy: Math.max(model.bestAccuracy || 0, bestValidationScore),
    savedAt: new Date().toISOString()
  } : Core.serialize(model);
  return snapshot;
}
function sendCheckpoint(force) {
  const now = Date.now();
  const validation = evaluateAndProtect();
  const snapshot = checkpointSnapshot();
  self.postMessage({
    type: "metrics",
    metrics: {
      steps: model.steps,
      examplesSeen: model.examplesSeen,
      trainLoss: lastLoss,
      trainAccuracy: lastAccuracy,
      validationAccuracy: validation.accuracy,
      balancedAccuracy: validation.balancedAccuracy,
      validationLoss: validation.loss,
      avgReward: totalReward / Math.max(1, totalBatchSamples),
      bestAccuracy: bestValidationScore,
      recoveryCount,
      learningRateScale,
      focusKey: dataset.focusKey,
      validationCount: validation.count,
      validationClasses: validation.classes,
      labels: model.labels.length,
      time: now
    },
    checkpoint: snapshot,
    finalCheckpoint: !!force
  });
  lastMetricsAt = now;
}
function loop() {
  if (!running) return;
  const start = performance.now();
  let batches = 0;
  while (running && batches < 2 && performance.now() - start < 40) {
    const batch = [];
    for (let i = 0; i < 32; i++) batch.push(pickTrainingItem());
    const learningRate = Math.max(0.006, 0.02 / (1 + model.steps / 7000)) * learningRateScale;
    const result = Core.trainBatch(model, batch, learningRate);
    lastLoss = result.loss;
    lastAccuracy = result.accuracy;
    totalReward += result.reward * result.used;
    totalBatchSamples += result.used;
    batches++;
  }
  if (model.steps >= nextEvaluationStep) {
    sendCheckpoint(false);
    nextEvaluationStep = model.steps + 120;
  } else if (Date.now() - lastMetricsAt > 12000) {
    sendCheckpoint(false);
  }
  if (batches > 0) {
    self.postMessage({
      type: "tick",
      steps: model.steps,
      examplesSeen: model.examplesSeen,
      lastLoss,
      lastAccuracy,
      avgReward: totalReward / Math.max(1, totalBatchSamples)
    });
  }
  setTimeout(loop, 12);
}
self.onmessage = function (event) {
  const message = event.data || {};
  if (message.type === "init") {
    dataset = Core.buildDataset(message.focus || "", message.curatedExamples || []);
    dataset.byLabel = {};
    dataset.train.forEach(function (row) {
      (dataset.byLabel[row.label] || (dataset.byLabel[row.label] = [])).push(row);
    });
    activeAllLabels = Core.FOCUS.all.filter(function (label) { return dataset.byLabel[label] && dataset.byLabel[label].length; });
    focusLabels = dataset.focusLabels || Core.FOCUS.all;
    activeFocusLabels = focusLabels.filter(function (label) { return dataset.byLabel[label] && dataset.byLabel[label].length; });
    if (!activeFocusLabels.length) activeFocusLabels = activeAllLabels;
    model = Core.createModel(message.modelState || null);
    random = makeRandom((Date.now() ^ 0x5bd1e995) >>> 0);
    const initial = Core.evaluate(model, dataset.validation);
    bestValidationScore = Number(initial.balancedAccuracy) || Number(initial.accuracy) || 0;
    bestValidationLoss = Number(initial.loss) || Infinity;
    bestCheckpoint = Core.serialize(model);
    model.bestAccuracy = Math.max(model.bestAccuracy || 0, bestValidationScore);
    self.postMessage({
      type: "ready",
      labels: model.labels.length,
      trainCount: dataset.train.length,
      validationCount: dataset.validation.length,
      focusKey: dataset.focusKey,
      focusLabels: activeFocusLabels,
      steps: model.steps,
      examplesSeen: model.examplesSeen,
      checkpoint: Core.serialize(model),
      metrics: {
        validationAccuracy: initial.accuracy,
        balancedAccuracy: initial.balancedAccuracy,
        validationLoss: initial.loss,
        bestAccuracy: bestValidationScore,
        avgReward: 0,
        recoveryCount: 0,
        steps: model.steps,
        examplesSeen: model.examplesSeen
      }
    });
  } else if (message.type === "start") {
    if (!model || !dataset) {
      self.postMessage({ type: "error", message: "Trainingsmodell ist noch nicht geladen." });
      return;
    }
    if (running) return;
    running = true;
    self.postMessage({ type: "status", status: "running" });
    loop();
  } else if (message.type === "pause") {
    running = false;
    if (model && dataset) sendCheckpoint(true);
    self.postMessage({ type: "status", status: "paused" });
  } else if (message.type === "stop") {
    running = false;
    if (model && dataset) sendCheckpoint(true);
    self.postMessage({ type: "status", status: "stopped" });
  } else if (message.type === "predict") {
    if (!model) {
      self.postMessage({ type: "prediction", id: message.id, error: "Model not ready" });
      return;
    }
    self.postMessage({ type: "prediction", id: message.id, result: Core.predict(model, message.text || "") });
  }
};
