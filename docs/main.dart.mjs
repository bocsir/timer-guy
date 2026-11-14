// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(
      await _compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string'], importedStringConstants: ''};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

let _isCompileStreamingSupported;
async function _compileStreaming(source, builtins) {
  _isCompileStreamingSupported ??= WebAssembly.compileStreaming(
    new Response(
      new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),
      {headers: {'Content-Type': 'application/wasm'}},
    ),
    builtins,
  ).then(() => false, (e) => e instanceof WebAssembly.CompileError);
  if (await _isCompileStreamingSupported) {
    return WebAssembly.compileStreaming(source, builtins);
  }
  return WebAssembly.compile(await (await source).arrayBuffer(), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            AB: (decoder, codeUnits) => decoder.decode(codeUnits),
      AC: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      AD: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      AE: x0 => x0.screen,
      AF: (x0,x1) => x0.replaceWith(x1),
      AG: x0 => x0.languages,
      AH: x0 => x0.innerHeight,
      AI: a => a.pop(),
      AJ: x0 => x0.completed,
      AK: x0 => x0.openCursor(),
      AL: x0 => x0.size,
      B: s => printToConsole(s),
      BB: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      BC: Function.prototype.call.bind(DataView.prototype.setFloat64),
      BD: (o, i) => o[i],
      BE: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      BF: (x0,x1) => { x0.className = x1 },
      BG: (x0,x1) => x0.observe(x1),
      BH: x0 => x0.height,
      BI: x0 => new WeakRef(x0),
      BJ: x0 => x0.ready,
      BK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      BL: x0 => x0.parentNode,
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: () => new TextDecoder("utf-8", {fatal: true}),
      CC: o => o.byteOffset,
      CD: o => o.length,
      CE: (x0,x1) => x0.removeProperty(x1),
      CF: (x0,x1) => { x0.tabIndex = x1 },
      CG: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      CH: x0 => x0.width,
      CI: x0 => x0.deref(),
      CJ: x0 => x0.tracks,
      CK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      CL: x0 => x0.length,
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: () => new TextDecoder("utf-8", {fatal: false}),
      DC: o => o.buffer,
      DD: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      DE: (x0,x1) => x0.appendChild(x1),
      DF: (x0,x1) => { x0.action = x1 },
      DG: x0 => new ResizeObserver(x0),
      DH: x0 => x0.clientHeight,
      DI: () => globalThis.WeakRef,
      DJ: () => globalThis.window.ImageDecoder,
      DK: (x0,x1) => { x0.onerror = x1 },
      DL: x0 => x0.files,
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: s => s.trimLeft(),
      EC: (b, o) => new DataView(b, o),
      ED: x0 => x0.state,
      EE: x0 => x0.debugShowSemanticsNodes,
      EF: (x0,x1) => { x0.method = x1 },
      EG: x0 => globalThis.parseFloat(x0),
      EH: x0 => x0.clientWidth,
      EI: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      EJ: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      EK: x0 => x0.error,
      EL: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      F: () => new Error().stack,
      FB: (a, i, v) => a[i] = v,
      FC: (b, o, l) => new DataView(b, o, l),
      FD: x0 => x0.hash,
      FE: (o, c) => o instanceof c,
      FF: (x0,x1) => { x0.noValidate = x1 },
      FG: (x0,x1) => x0.getComputedStyle(x1),
      FH: x0 => x0.innerWidth,
      FI: (a, s, e) => a.slice(s, e),
      FJ: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      FK: (x0,x1) => { x0.onsuccess = x1 },
      FL: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      G: s => JSON.stringify(s),
      GB: (l, r) => l === r,
      GC: Function.prototype.call.bind(DataView.prototype.getUint8),
      GD: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      GE: x0 => x0.vendor,
      GF: x0 => x0.isConnected,
      GG: x0 => x0.documentElement,
      GH: (x0,x1) => x0.removeChild(x1),
      GI: x0 => x0.createOscillator(),
      GJ: () => new FileReader(),
      GK: x0 => x0.continue(),
      GL: (x0,x1) => { x0.display = x1 },
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: s => s.toUpperCase(),
      HC: Function.prototype.call.bind(DataView.prototype.setUint8),
      HD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      HE: (x0,x1) => x0.createTextNode(x1),
      HF: x0 => x0.click(),
      HG: x0 => x0.computedStyleMap(),
      HH: x0 => x0.firstChild,
      HI: x0 => x0.createGain(),
      HJ: (x0,x1) => x0.readAsArrayBuffer(x1),
      HK: x0 => x0.result,
      HL: x0 => x0.style,
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: Object.is,
      IC: Function.prototype.call.bind(DataView.prototype.getFloat64),
      ID: x0 => x0.state,
      IE: (x0,x1) => { x0.nonce = x1 },
      IF: (x0,x1) => x0.getElementsByClassName(x1),
      IG: (x0,x1) => x0.get(x1),
      IH: x0 => x0.viewConstraints,
      II: (x0,x1,x2) => x0.setValueAtTime(x1,x2),
      IJ: x0 => x0.result,
      IK: x0 => x0.target,
      IL: (x0,x1) => { x0.accept = x1 },
      J: (s, p, i) => s.lastIndexOf(p, i),
      JB: (x0,x1) => x0.test(x1),
      JC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      JD: (x0,x1,x2) => x0.addEventListener(x1,x2),
      JE: x0 => x0.nonce,
      JF: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      JG: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      JH: x0 => x0.hostElement,
      JI: (x0,x1,x2) => x0.linearRampToValueAtTime(x1,x2),
      JJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      JK: (x0,x1,x2) => x0.transaction(x1,x2),
      JL: (x0,x1) => { x0.multiple = x1 },
      K: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      KB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      KC: (t, s) => t.set(s),
      KD: (x0,x1) => x0.go(x1),
      KE: () => globalThis.window.flutterConfiguration,
      KF: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      KG: x0 => x0.matches,
      KH: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      KI: (x0,x1) => x0.connect(x1),
      KJ: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      KK: (x0,x1) => x0.objectStore(x1),
      KL: (x0,x1) => { x0.draggable = x1 },
      L: o => o === undefined,
      LB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      LC: Function.prototype.call.bind(DataView.prototype.setFloat32),
      LD: (x0,x1) => x0.append(x1),
      LE: (x0,x1) => x0.attachShadow(x1),
      LF: (x0,x1) => x0.contains(x1),
      LG: (x0,x1) => x0.matchMedia(x1),
      LH: x0 => ({runApp: x0}),
      LI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      LJ: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      LK: (x0,x1) => x0.getAllKeys(x1),
      LL: (x0,x1) => { x0.type = x1 },
      M: o => String(o),
      MB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      MC: Function.prototype.call.bind(DataView.prototype.getFloat32),
      MD: (x0,x1) => { x0.textContent = x1 },
      ME: x0 => x0.preventDefault(),
      MF: (s) => +s,
      MG: x0 => x0.matches,
      MH: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      MI: (x0,x1) => x0.start(x1),
      MJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      MK: x0 => x0.key,
      ML: x0 => ({type: x0}),
      N: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      NB: Function.prototype.call.bind(String.prototype.toLowerCase),
      NC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      ND: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      NE: (x0,x1) => x0.contains(x1),
      NF: x0 => x0.target,
      NG: x0 => x0.timeStamp,
      NH: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      NI: (x0,x1) => x0.stop(x1),
      NJ: () => new XMLHttpRequest(),
      NK: (o, t) => typeof o === t,
      NL: (x0,x1) => new Blob(x0,x1),
      O: (x0,x1) => x0.didCreateEngineInitializer(x1),
      OB: (o, p, r) => o.replace(p, () => r),
      OC: Function.prototype.call.bind(DataView.prototype.getUint32),
      OD: x0 => x0.parentElement,
      OE: (x0,x1) => x0.focus(x1),
      OF: (x0,x1) => x0.dispatchEvent(x1),
      OG: (x0,x1) => x0.hasAttribute(x1),
      OH: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      OI: (x0,x1) => { x0.onended = x1 },
      OJ: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      OK: x0 => x0.close(),
      OL: x0 => globalThis.URL.revokeObjectURL(x0),
      P: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      PB: (o, p, r) => o.replaceAll(p, () => r),
      PC: Function.prototype.call.bind(DataView.prototype.setUint32),
      PD: (x0,x1) => x0.querySelectorAll(x1),
      PE: (x0,x1) => x0.closest(x1),
      PF: (x0,x1) => x0.createEvent(x1),
      PG: x0 => x0.type,
      PH: () => typeof dartUseDateNowForTicks !== "undefined",
      PI: x0 => x0.disconnect(),
      PJ: x0 => x0.send(),
      PK: (x0,x1) => x0.delete(x1),
      PL: (x0,x1) => { x0.download = x1 },
      Q: (wasmFunction,f) => finalizeWrapper(f, function() { return wasmFunction(f,arguments.length) }),
      QB: (x0,x1) => x0[x1],
      QC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      QD: x0 => x0.length,
      QE: (x0,x1) => x0.getAttribute(x1),
      QF: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      QG: (x0,x1) => x0.getModifierState(x1),
      QH: () => Date.now(),
      QI: x0 => x0.destination,
      QJ: x0 => x0.type,
      QK: (x0,x1,x2) => x0.put(x1,x2),
      QL: (x0,x1) => { x0.target = x1 },
      R: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      RB: x0 => x0.index,
      RC: Function.prototype.call.bind(DataView.prototype.getInt32),
      RD: (x0,x1) => x0.item(x1),
      RE: x0 => x0.activeElement,
      RF: x0 => x0.readText(),
      RG: x0 => x0.buttons,
      RH: () => 1000 * performance.now(),
      RI: x0 => x0.gain,
      RJ: x0 => x0.response,
      RK: (x0,x1) => x0.createObjectStore(x1),
      RL: (x0,x1) => { x0.href = x1 },
      S: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      SB: x0 => x0.pop(),
      SC: Function.prototype.call.bind(DataView.prototype.setInt32),
      SD: x0 => x0.userAgent,
      SE: (x0,x1) => x0.add(x1),
      SF: x0 => x0.clipboard,
      SG: x0 => x0.ctrlKey,
      SH: x0 => new Uint8Array(x0),
      SI: (x0,x1) => { x0.value = x1 },
      SJ: (x0,x1) => { x0.responseType = x1 },
      SK: x0 => x0.version,
      SL: x0 => x0.extraAssets,
      T: x0 => new Promise(x0),
      TB: x0 => x0.flags,
      TC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      TD: x0 => x0.maxTouchPoints,
      TE: x0 => x0.classList,
      TF: (x0,x1) => x0.writeText(x1),
      TG: x0 => x0.getBoundingClientRect(),
      TH: (x0,x1,x2) => x0.slice(x1,x2),
      TI: x0 => x0.frequency,
      TJ: x0 => x0.vendor,
      TK: x0 => x0.objectStoreNames,
      TL: x0 => x0.fontManifest,
      U: (x0,x1,x2) => x0.call(x1,x2),
      UB: s => s.trim(),
      UC: o => o instanceof Uint16Array,
      UD: x0 => x0.platform,
      UE: x0 => x0.data,
      UF: x0 => x0.unlock(),
      UG: x0 => x0.y,
      UH: (x0,x1) => x0.decode(x1),
      UI: (x0,x1) => { x0.type = x1 },
      UJ: x0 => x0.navigator,
      UK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      UL: x0 => x0.assetManifest,
      V: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      VB: (a, s) => a.join(s),
      VC: Function.prototype.call.bind(DataView.prototype.getUint16),
      VD: x0 => x0.navigator,
      VE: x0 => x0.scrollTop,
      VF: (x0,x1) => x0.lock(x1),
      VG: x0 => x0.x,
      VH: (x0,x1) => x0.adoptText(x1),
      VI: x0 => x0.currentTime,
      VJ: () => globalThis.window,
      VK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      VL: x0 => x0.buildConfig,
      W: x0 => new Array(x0),
      WB: x0 => x0.random(),
      WC: Function.prototype.call.bind(DataView.prototype.setUint16),
      WD: s => new Date(s * 1000).getTimezoneOffset() * 60,
      WE: (handle) => clearTimeout(handle),
      WF: x0 => x0.orientation,
      WG: x0 => x0.top,
      WH: x0 => x0.first(),
      WI: x0 => x0.resume(),
      WJ: x0 => new Blob(x0),
      WK: (x0,x1) => { x0.onupgradeneeded = x1 },
      WL: x0 => x0.length,
      X: o => [o],
      XB: () => globalThis.Math,
      XC: o => o instanceof Int16Array,
      XD: Date.now,
      XE: (x0,x1) => x0.removeAttribute(x1),
      XF: (x0,x1) => x0.querySelector(x1),
      XG: x0 => x0.left,
      XH: x0 => x0.next(),
      XI: x0 => x0.state,
      XJ: x0 => globalThis.fetch(x0),
      XK: x0 => x0.indexedDB,
      XL: x0 => x0.getReader(),
      Y: (o0, o1) => [o0, o1],
      YB: (x0,x1) => x0.error(x1),
      YC: Function.prototype.call.bind(DataView.prototype.getInt16),
      YD: (x0,x1,x2) => x0.setAttribute(x1,x2),
      YE: (x0,x1) => { x0.value = x1 },
      YF: (x0,x1) => { x0.content = x1 },
      YG: x0 => x0.offsetTop,
      YH: x0 => x0.current(),
      YI: () => new AudioContext(),
      YJ: x0 => x0.arrayBuffer(),
      YK: x0 => x0.self,
      YL: x0 => x0.value,
      Z: (o0, o1, o2) => [o0, o1, o2],
      ZB: () => globalThis.console,
      ZC: Function.prototype.call.bind(DataView.prototype.setInt16),
      ZD: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      ZE: (x0,x1) => { x0.value = x1 },
      ZF: x0 => x0.head,
      ZG: x0 => x0.scrollLeft,
      ZH: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      ZI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      ZJ: (x0,x1,x2) => x0.insertBefore(x1,x2),
      ZK: (x0,x1) => x0.getRandomValues(x1),
      ZL: x0 => x0.done,
      a: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      aB: s => s.trimRight(),
      aC: o => o instanceof Uint8ClampedArray,
      aD: x0 => x0.style,
      aE: x0 => x0.value,
      aF: (x0,x1) => { x0.name = x1 },
      aG: x0 => x0.offsetLeft,
      aH: x0 => x0.v8BreakIterator,
      aI: (x0,x1,x2) => x0.addEventListener(x1,x2),
      aJ: x0 => x0.id,
      aK: () => globalThis.crypto,
      aL: x0 => x0.read(),
      b: (x0,x1,x2) => { x0[x1] = x2 },
      bB: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      bC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      bD: (x0,x1) => x0.createElement(x1),
      bE: x0 => x0.selectionDirection,
      bF: (x0,x1) => { x0.title = x1 },
      bG: x0 => x0.offsetParent,
      bH: () => globalThis.Intl,
      bI: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      bJ: x0 => x0.offsetHeight,
      bK: l => new DataView(new ArrayBuffer(l)),
      bL: x0 => x0.body,
      c: o => o,
      cB: () => ({}),
      cC: Function.prototype.call.bind(DataView.prototype.setInt8),
      cD: x0 => x0.body,
      cE: x0 => x0.selectionStart,
      cF: () => globalThis.document,
      cG: x0 => x0.offsetY,
      cH: (x0,x1) => x0.segment(x1),
      cI: () => globalThis.document,
      cJ: x0 => x0.offsetWidth,
      cK: x0 => x0.hostElement,
      cL: (x0,x1) => new OffscreenCanvas(x0,x1),
      d: (o, p) => o[p],
      dB: (o, p, v) => o[p] = v,
      dC: Function.prototype.call.bind(DataView.prototype.getInt8),
      dD: x0 => x0.remove(),
      dE: x0 => x0.selectionEnd,
      dF: (x0,x1) => x0.vibrate(x1),
      dG: x0 => x0.offsetX,
      dH: x0 => x0.index,
      dI: x0 => x0.close(),
      dJ: x0 => x0.stopPropagation(),
      dK: x0 => x0.location,
      dL: x0 => x0.assetBase,
      e: () => globalThis,
      eB: () => [],
      eC: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      eD: (x0,x1) => x0.getPropertyValue(x1),
      eE: x0 => x0.value,
      eF: (o, p) => p in o,
      eG: x0 => x0.deltaMode,
      eH: x0 => x0.next(),
      eI: x0 => x0.height,
      eJ: x0 => x0.disabled,
      eK: (x0,x1) => x0.getModifierState(x1),
      eL: x0 => x0.loader,
      f: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      fB: (a, i) => a.push(i),
      fC: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      fD: (x0,x1) => x0.warn(x1),
      fE: x0 => x0.selectionDirection,
      fF: x0 => x0.arrayBuffer(),
      fG: x0 => x0.deltaY,
      fH: x0 => x0.value,
      fI: x0 => x0.width,
      fJ: (x0,x1) => { x0.min = x1 },
      fK: x0 => x0.metaKey,
      fL: () => globalThis._flutter,
      g: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gB: b => !!b,
      gC: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      gD: x0 => x0.console,
      gE: x0 => x0.selectionStart,
      gF: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      gG: x0 => x0.deltaX,
      gH: x0 => x0.done,
      gI: (x0,x1,x2,x3,x4,x5) => x0.createImageBitmap(x1,x2,x3,x4,x5),
      gJ: (x0,x1) => { x0.max = x1 },
      gK: x0 => x0.altKey,
      h: (x0,x1) => ({addView: x0,removeView: x1}),
      hB: x0 => new Int8Array(x0),
      hC: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      hD: (x0,x1) => { x0.id = x1 },
      hE: x0 => x0.selectionEnd,
      hF: x0 => x0.status,
      hG: x0 => x0.wheelDeltaY,
      hH: (o, m, a) => o[m].apply(o, a),
      hI: (x0,x1) => x0.createImageBitmap(x1),
      hJ: (x0,x1) => { x0.disabled = x1 },
      hK: x0 => x0.ctrlKey,
      i: (x0,x1) => x0.exec(x1),
      iB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      iC: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      iD: (x0,x1) => x0.requestAnimationFrame(x1),
      iE: (x0,x1) => { x0.name = x1 },
      iF: (x0,x1) => x0.fetch(x1),
      iG: x0 => x0.wheelDeltaX,
      iH: x0 => x0.iterator,
      iI: x0 => new Blob(x0),
      iJ: (x0,x1) => { x0.scrollLeft = x1 },
      iK: x0 => x0.isComposing,
      j: x0 => x0.length,
      jB: x0 => new Uint8Array(x0),
      jC: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      jD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      jE: (x0,x1) => { x0.placeholder = x1 },
      jF: x0 => x0.content,
      jG: x0 => x0.bottom,
      jH: () => globalThis.Symbol,
      jI: x0 => x0.close(),
      jJ: (x0,x1) => { x0.spellcheck = x1 },
      jK: x0 => x0.code,
      k: o => o,
      kB: x0 => new Uint8ClampedArray(x0),
      kC: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      kD: x0 => x0.now(),
      kE: (x0,x1) => { x0.autocomplete = x1 },
      kF: x0 => x0.document,
      kG: x0 => x0.right,
      kH: (x0,x1) => new Intl.Segmenter(x0,x1),
      kI: x0 => x0.naturalHeight,
      kJ: (x0,x1) => { x0.disabled = x1 },
      kK: x0 => x0.repeat,
      l: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      lB: x0 => new Int16Array(x0),
      lC: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      lD: x0 => x0.performance,
      lE: (x0,x1) => { x0.type = x1 },
      lF: x0 => x0.language,
      lG: x0 => x0.clientY,
      lH: x0 => x0.Segmenter,
      lI: x0 => x0.naturalWidth,
      lJ: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9) => x0.drawImage(x1,x2,x3,x4,x5,x6,x7,x8,x9),
      lK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      m: (x0,x1) => { x0.lastIndex = x1 },
      mB: x0 => new Uint16Array(x0),
      mC: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      mD: (x0,x1) => x0.unregister(x1),
      mE: (x0,x1) => { x0.name = x1 },
      mF: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      mG: x0 => x0.clientX,
      mH: x0 => x0.buffer,
      mI: (x0,x1) => { x0.src = x1 },
      mJ: (x0,x1) => x0.getContext(x1),
      mK: (x0,x1) => x0.querySelector(x1),
      n: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      nB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      nC: x0 => x0.history,
      nD: () => globalThis.window.FinalizationRegistry,
      nE: (x0,x1) => { x0.placeholder = x1 },
      nF: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      nG: x0 => x0.changedTouches,
      nH: x0 => x0.wasmMemory,
      nI: x0 => x0.displayHeight,
      nJ: (x0,x1) => { x0.height = x1 },
      nK: (x0,x1) => x0.createElement(x1),
      o: o => o instanceof RegExp,
      oB: x0 => new Int32Array(x0),
      oC: () => globalThis.window,
      oD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      oE: (x0,x1) => { x0.scrollTop = x1 },
      oF: (x0,x1) => x0.querySelector(x1),
      oG: x0 => x0.key,
      oH: () => globalThis.window._flutter_skwasmInstance,
      oI: x0 => x0.displayWidth,
      oJ: (x0,x1) => { x0.width = x1 },
      oK: (x0,x1) => x0.appendChild(x1),
      p: o => o,
      pB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      pC: x0 => x0.search,
      pD: x0 => new window.FinalizationRegistry(x0),
      pE: x0 => x0.tagName,
      pF: (x0,x1) => x0.querySelectorAll(x1),
      pG: x0 => x0.identifier,
      pH: () => new TextDecoder(),
      pI: x0 => x0.duration,
      pJ: (x0,x1) => x0.transferFromImageBitmap(x1),
      pK: x0 => x0.body,
      q: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      qB: x0 => new Uint32Array(x0),
      qC: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      qD: x0 => x0.scale,
      qE: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      qF: x0 => x0.tabIndex,
      qG: x0 => x0.touches,
      qH: (map, o, v) => map.set(o, v),
      qI: (x0,x1) => ({frameIndex: x0,completeFramesOnly: x1}),
      qJ: x0 => x0.rasterEndMilliseconds,
      qK: (x0,x1) => { x0.id = x1 },
      r: x0 => x0.dotAll,
      rB: x0 => new Float32Array(x0),
      rC: x0 => x0.location,
      rD: x0 => x0.visualViewport,
      rE: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      rF: x0 => x0.parentNode,
      rG: x0 => x0.pressure,
      rH: (map, o) => map.get(o),
      rI: (x0,x1) => x0.decode(x1),
      rJ: x0 => x0.rasterStartMilliseconds,
      rK: x0 => x0.click(),
      s: x0 => x0.unicode,
      sB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      sC: x0 => x0.pathname,
      sD: x0 => x0.devicePixelRatio,
      sE: x0 => x0.visibilityState,
      sF: x0 => x0.clientY,
      sG: x0 => x0.tiltY,
      sH: () => new WeakMap(),
      sI: x0 => x0.image,
      sJ: x0 => x0.imageBitmaps,
      sK: (x0,x1) => x0.removeChild(x1),
      t: x0 => x0.ignoreCase,
      tB: x0 => new Float64Array(x0),
      tC: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      tD: (d, digits) => d.toFixed(digits),
      tE: x0 => x0.hasFocus(),
      tF: x0 => x0.clientX,
      tG: x0 => x0.tiltX,
      tH: x0 => x0.debugSkipFontRetryDelay,
      tI: x0 => x0.close(),
      tJ: x0 => x0.canvasKitMaximumSurfaces,
      tK: x0 => x0.firstChild,
      u: x0 => x0.multiline,
      uB: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      uC: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      uD: x0 => x0.maxHeight,
      uE: x0 => x0.relatedTarget,
      uF: x0 => x0.shiftKey,
      uG: x0 => x0.pointerType,
      uH: (x0,x1,x2) => x0.set(x1,x2),
      uI: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      uJ: (x0,x1,x2) => x0.open(x1,x2),
      uK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      v: (string, token) => string.split(token),
      vB: x0 => new ArrayBuffer(x0),
      vC: o => Object.keys(o),
      vD: x0 => x0.maxWidth,
      vE: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      vF: x0 => x0.disconnect(),
      vG: x0 => x0.pointerId,
      vH: x0 => x0.fontFallbackBaseUrl,
      vI: x0 => new window.ImageDecoder(x0),
      vJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      vK: (x0,x1) => x0.item(x1),
      w: o => o instanceof Array,
      wB: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      wC: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      wD: x0 => x0.minHeight,
      wE: x0 => x0.keyCode,
      wF: x0 => new Intl.Locale(x0),
      wG: x0 => x0.getCoalescedEvents(),
      wH: (handle) => clearInterval(handle),
      wI: x0 => x0.name,
      wJ: (x0,x1) => x0.contains(x1),
      wK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      x: (a, i) => a[i],
      xB: (x0,x1,x2) => new DataView(x0,x1,x2),
      xC: f => f.dartFunction,
      xD: x0 => x0.minWidth,
      xE: (x0,x1) => x0.scrollIntoView(x1),
      xF: x0 => x0.region,
      xG: x0 => x0.blur(),
      xH: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      xI: x0 => x0.repetitionCount,
      xJ: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      xK: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      y: a => a.length,
      yB: (o, p) => o[p],
      yC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      yD: x0 => x0.height,
      yE: x0 => x0.multiViewEnabled,
      yF: x0 => x0.script,
      yG: x0 => x0.button,
      yH: () => Date.now(),
      yI: x0 => x0.frameCount,
      yJ: (x0,x1) => x0.getAll(x1),
      yK: x0 => globalThis.URL.createObjectURL(x0),
      z: (string, times) => string.repeat(times),
      zB: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      zC: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      zD: x0 => x0.width,
      zE: x0 => x0.parent,
      zF: x0 => x0.language,
      zG: (x0,x1) => x0.prepend(x1),
      zH: (a, i) => a.splice(i, 1),
      zI: x0 => x0.selectedTrack,
      zJ: x0 => x0.value,
      zK: x0 => x0.name,

    };

    const baseImports = {
      _: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
