export const STEPS_PER_MEADOW = 8;
export const MEADOWS = [
  { id: 'morning', name: '晨光草地', note: '跟着跳跳，认出每一个假名。' },
  { id: 'dandelion', name: '蒲公英小径', note: '再跳几步，风里都是花的香气。' },
  { id: 'mint', name: '薄荷溪谷', note: '溪水轻轻响，慢慢记也没关系。' },
  { id: 'sunset', name: '落日花田', note: '把今天认识的假名，装进口袋。' }
];

export class Journey {
  constructor(saved) {
    this.hops = saved?.version === 1 && Number.isSafeInteger(saved.hops) && saved.hops >= 0 ? saved.hops : 0;
  }

  get view() {
    const completed = Math.floor(this.hops / STEPS_PER_MEADOW);
    const step = this.hops % STEPS_PER_MEADOW;
    return { meadow: MEADOWS[completed % MEADOWS.length], chapter: completed + 1,
      step, remaining: STEPS_PER_MEADOW - step };
  }

  record(kind) {
    if (kind !== 'correct' || this.hops === Number.MAX_SAFE_INTEGER) return false;
    this.hops += 1;
    return this.hops % STEPS_PER_MEADOW === 0;
  }

  savedProgress() {
    return { version: 1, hops: this.hops };
  }
}
