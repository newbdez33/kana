const test = require('node:test');
const assert = require('node:assert/strict');
const { ImpactSession, stageFor, levels } = require('../preview/impact/model.js');
const { createHaptics } = require('../app/haptics.js');
const { createSoundPlayer: createSound } = require('../app/audio.js');
const pool = [['a','あ','ア'],['i','い','イ'],['u','う','ウ'],['e','え','エ']];

function session() {
  let now = 0;
  const game = new ImpactSession(pool, {now: () => now, random: () => 0.3});
  return {game, advance: (ms) => {now += ms;}};
}

test('feedback stages use five bounded bands', () => {
  assert.deepEqual([0,4,5,9,10,19,20,29,30,1000].map(stageFor), [0,0,1,1,2,2,3,3,4,4]);
  assert.deepEqual(levels.map(level => level.bpm), [0,0,80,100,120]);
});

test('revealed corrections do not add to the preview streak', () => {
  const {game,advance} = session();
  advance(500);
  assert.equal(game.answer(game.question.correctIndex).combo, 1);
  advance(500);
  const correct = game.question.correctIndex;
  assert.equal(game.answer((correct+1)%4).broken, 1);
  assert.equal(game.answer((correct+2)%4).kind, 'retry');
  advance(200);
  assert.equal(game.answer(correct).kind, 'correction');
  assert.equal(game.combo, 0);
  assert.equal(game.attempts, 2);
  assert.equal(game.correct, 1);
  advance(500);
  assert.equal(game.answer(game.question.correctIndex).combo, 1);
});

test('deadline taps break the streak and a timeout is counted only once', () => {
  const {game,advance} = session();
  advance(500); game.answer(game.question.correctIndex);
  advance(5000);
  const result = game.answer(game.question.correctIndex);
  assert.equal(result.kind, 'timeout');
  assert.equal(result.broken, 1);
  assert.equal(game.attempts, 2);
  assert.equal(game.tick().kind, 'idle');
  assert.equal(game.answer(game.question.correctIndex).kind, 'correction');
  assert.equal(game.combo, 0);
});

test('pause preserves remaining time and stages do not shorten the deadline', () => {
  const {game,advance} = session();
  for (let i=0;i<35;i++) {advance(400); game.answer(game.question.correctIndex);}
  advance(1000);
  game.setPaused(true); advance(60000);
  assert.equal(game.remaining(), 4000);
  assert.equal(game.tick().kind, 'idle');
  game.setPaused(false); advance(500);
  assert.equal(game.answer(game.question.correctIndex).combo, 36);
  assert.equal(game.remaining(), 5000);
});

test('a new personal record is celebrated once per run after a prior best', () => {
  const {game,advance} = session();
  for (let i=0;i<5;i++) {advance(100); assert.equal(game.answer(game.question.correctIndex).record, false);}
  advance(100); game.answer((game.question.correctIndex+1)%4);
  game.answer(game.question.correctIndex);
  const records=[];
  for(let i=0;i<8;i++){advance(100); records.push(game.answer(game.question.correctIndex).record);}
  assert.equal(records.filter(Boolean).length,1);
  assert.equal(records[5],true);
});

function nativeHost(version, overrides = {}) {
  return {document:{hidden:false},xhs:{launchOptions:{miniToolEnv:{buildVersion:version}},miniTool:Object.assign({vibrateShort:async()=>({errMsg:'vibrateShort:ok'})},overrides)}};
}

test('native haptics require version 9.50 and send only the public strength field', async () => {
  const calls=[];
  const controller=createHaptics(nativeHost(9500001,{vibrateShort:async options=>{calls.push(options);}}), null, ()=>1000);
  assert.equal((await controller.prepare()).mode,'native');
  assert.equal((await controller.pulse('medium',true)).status,'requested');
  assert.deepEqual(calls,[{type:'medium'}]);
  const old=createHaptics(nativeHost(9490001),{available:()=>true,pulse:()=>{throw Error('No browser fallback in a container');}});
  assert.equal((await old.prepare()).mode,'unsupported');
  assert.equal((await old.pulse('heavy',true)).status,'unsupported');
});

test('haptics do not run without a gesture, while hidden, or for invalid strengths', async () => {
  let calls=0;
  const host=nativeHost(9500001,{vibrateShort:async()=>{calls++;}});
  const controller=createHaptics(host);
  await controller.prepare();
  assert.equal((await controller.pulse('light',false)).status,'skipped');
  host.document.hidden=true;
  assert.equal((await controller.pulse('light',true)).status,'skipped');
  host.document.hidden=false;
  assert.equal((await controller.pulse('invalid',true)).status,'skipped');
  assert.equal(calls,0);
});

test('pending and rapid haptic calls are coalesced; failures stay failures', async () => {
  let now=0, release, calls=0;
  const host=nativeHost(9500001,{vibrateShort:()=>{calls++;return new Promise(resolve=>{release=resolve;});}});
  const controller=createHaptics(host,null,()=>now);
  await controller.prepare();
  const first=controller.pulse('light',true);
  assert.equal((await controller.pulse('heavy',true)).status,'skipped');
  release(); await first;
  now=100;
  assert.equal((await controller.pulse('light',true)).status,'skipped');
  now=400;
  host.xhs.miniTool.vibrateShort=async()=>{calls++;throw {errCode:10002,errMsg:'vibrateShort:fail unavailable'};};
  assert.equal((await controller.pulse('heavy',true)).status,'failed');
  assert.equal(calls,2);
});

test('browser vibration reports acceptance without claiming physical feedback', async () => {
  let now=0;
  const host={document:{hidden:false}};
  const controller=createHaptics(host,{available:()=>true,pulse:()=>false},()=>now);
  assert.equal((await controller.prepare()).mode,'browser');
  assert.equal((await controller.pulse('light',true)).status,'failed');
  const accepted=createHaptics(host,{available:()=>true,pulse:()=>true},()=>now);
  await accepted.prepare();
  assert.deepEqual(await accepted.pulse('light',true),{status:'requested',mode:'browser',type:'light'});
});

test('async native version detection fails closed without falling back to browser vibration', async () => {
  const host=nativeHost(0,{getLaunchOptions:async()=>({miniToolEnv:{buildVersion:9501002}})});
  const controller=createHaptics(host);
  assert.equal((await controller.prepare()).mode,'native');
  host.xhs.miniTool.getLaunchOptions=async()=>{throw Error('Unavailable');};
  assert.equal((await controller.prepare()).mode,'unsupported');
});

test('a stalled native haptic call releases the pending state without retrying', {timeout:2500}, async () => {
  let calls=0;
  const host=nativeHost(9500001,{vibrateShort:()=>{calls++;return new Promise(()=>{});}});
  const controller=createHaptics(host);
  await controller.prepare();
  const result=await controller.pulse('heavy',true);
  assert.equal(result.status,'failed');
  assert.equal(result.code,'timeout');
  assert.equal(calls,1);
  host.xhs.miniTool.vibrateShort=async()=>{calls++;};
  assert.equal((await controller.pulse('light',true)).status,'requested');
  assert.equal(calls,2);
});

function soundHost(suspended = false) {
  const events=[], timers=new Map();
  let next=0, resume;
  const parameter={setValueAtTime(){},exponentialRampToValueAtTime(){},cancelScheduledValues(){},setTargetAtTime(){}};
  class AudioContext {
    constructor(){events.push('context');this.currentTime=0;this.state=suspended?'suspended':'running';}
    resume(){return new Promise(resolve=>{resume=()=>{this.state='running';resolve();};});}
    createGain(){return {gain:parameter,connect(){},disconnect(){}};}
    createOscillator(){return {frequency:parameter,connect(){},disconnect(){},start(){events.push('start');},stop(){events.push('stop');}};}
  }
  const host={AudioContext,document:{hidden:false},navigator:{audioSession:{}},
    setTimeout(callback){timers.set(++next,callback);return next;},clearTimeout(id){timers.delete(id);}};
  Object.defineProperty(host.navigator.audioSession,'type',{set(value){events.push(value);}});
  return {host,events,timers,resume:()=>resume()};
}

test('preview audio starts only after a gesture and selects playback before creating the context', async () => {
  const {host,events,timers}=soundHost();
  const sound=createSound(host);
  sound.setRhythm(120,true);
  assert.equal(await sound.play('hit',4,false),false);
  assert.deepEqual(events,[]);
  assert.equal(timers.size,0);
  assert.equal(await sound.play('hit',4,true),true);
  assert.deepEqual(events.slice(0,2),['playback','context']);
  sound.stop();
  assert.equal(timers.size,0);
});

test('stopping a pending audio resume prevents a late hit from sounding', async () => {
  const setup=soundHost(true);
  const sound=createSound(setup.host);
  const pending=sound.play('hit',4,true);
  sound.stop(); setup.resume();
  assert.equal(await pending,false);
  assert.equal(setup.events.filter(event=>event==='start').length,0);
});

test('pure haptic tests can stop both the audible beat and its visual callback', async () => {
  const {host,timers}=soundHost();
  let beats=0;
  const sound=createSound(host,()=>beats++);
  await sound.play('hit',2,true);
  sound.setRhythm(80,true);
  assert.equal(timers.size,1);
  const oldTick=Array.from(timers.values())[0];
  sound.stop(); oldTick();
  assert.equal(beats,0);
  assert.equal(timers.size,0);
});
