// Runs one compiler stage (compiled to WebAssembly) on the given source.
// A fresh worker is used per run so global C state starts clean and
// runaway programs can be stopped with worker.terminate().
const MAX_LINES = 5000;

self.onmessage = async (e) => {
  const { stage, code } = e.data;
  const lines = [];
  let truncated = false;
  const push = (stream) => (text) => {
    if (lines.length < MAX_LINES) lines.push({ stream, text });
    else truncated = true;
  };
  try {
    importScripts(`wasm/${stage}.js`);
    const mod = await self[`make_${stage}`]({
      print: push("out"),
      printErr: push("err"),
    });
    mod.FS.writeFile("/input.txt", code);
    let status = 0;
    try {
      status = mod.callMain(["/input.txt"]);
    } catch (err) {
      if (err && err.name === "ExitStatus") status = err.status;
      else throw err;
    }
    self.postMessage({ ok: true, status, lines, truncated });
  } catch (err) {
    self.postMessage({ ok: false, error: String(err && err.message || err), lines });
  }
};
