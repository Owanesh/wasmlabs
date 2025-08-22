
# WASM & JavaScript Malware Experiments

## Scope
This repository is not a formal research project, but rather a collection of scripts and experiments related to trying out various things in WebAssembly (WASM), especially in the context of JavaScript malware. The goal is to explore and test the capabilities and limitations of WASM for handling JavaScript code, with a focus on practical experimentation rather than academic research.

## Sources
- The main dataset is the [javascript-malware-collection](https://github.com/HynekPetrak/javascript-malware-collection), which provides a variety of real-world JavaScript malware samples for experimentation.
- The [malware-jail](https://github.com/HynekPetrak/malware-jail) tool was used to obtain execution traces of JavaScript files in a controlled environment.

## Observations
- **93.08%** of the tested samples use Windows-specific `WScript` objects, which are not compatible with WASM and cannot be recompiled or executed in a WASM environment.
- The remaining **~7%** of samples either fail to complete execution or enter infinite loops, further limiting the applicability of WASM for direct analysis or execution of JavaScript malware.

## Scripts and Tools
This repo contains several scripts to automate and support the experiments:

- **wstrace.py**: Generates execution traces for each JavaScript file using `malware-jail`, saving the output as `jailed.txt`. Requires `jailme.js` from the malware-jail toolkit.
- **wserrorscanner.py**: Scans all processed files to identify those that resulted in errors, helping to diagnose the reasons for failed executions.  
- **wscanner.py**: Analyzes all trace files to determine how many samples use `WScript` or related Windows-specific objects.  `["ADODB_Stream", "ActiveXObject", "WScript.Shell"]`
- **wasm_validate.py**: Validates the generated WASM files after conversion to ensure correctness and compatibility.
- **js2wasmi.sh**: Converts JavaScript files to WASM using `porffor`, skipping the TAG section (which is not yet fully supported).

## Conclusion
These experiments show that the vast majority of JavaScript malware relies on Windows-specific features, making direct WASM-based analysis or recompilation infeasible. Only a small fraction of samples are theoretically compatible, but practical issues such as incomplete execution or infinite loops further reduce the effectiveness of this approach.

---

For more details, see the individual scripts and their documentation.