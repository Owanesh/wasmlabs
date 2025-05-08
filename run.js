const createAppModule = require('./wasibench/aritoh/arith.js');

createAppModule({
  arguments: ["3"],
  print: console.log,
  printErr: console.error
}).then((Module) => {
  Module.callMain(Module.arguments);
});
