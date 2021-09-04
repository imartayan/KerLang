



Split(['#pan-doc', '#pan-editor'], { sizes: [20, 80] })
Split(['#code-editor', '#compiler-output'])

let ace_editor = ace.edit('code-editor')
ace_editor.setTheme('ace/theme/dracula')

let output = ace.edit('compiler-output')
output.setTheme('ace/theme/dracula')
output.setReadOnly(true)

function loadFile(f) {
  f.text().then(txt => ace_editor.setValue(txt))
}


let toC = document.getElementById('toC')
let toPY = document.getElementById('toPY')
let toML = document.getElementById('toML')
let copy = document.getElementById('copy')

copy.addEventListener('click', () => {
  navigator.clipboard.writeText(output.getValue())
})

toC.addEventListener('click', () => {
  let res = Kerlang.generateC(ace_editor.getValue())
  output.setValue(res.result)
  output.session.setMode("ace/mode/c_cpp");
})

toPY.addEventListener('click', () => {
  let res = Kerlang.generatePY(ace_editor.getValue())
  output.setValue(res.result)
  output.session.setMode("ace/mode/python");
})

toML.addEventListener('click', () => {
  let res = Kerlang.generateML(ace_editor.getValue())
  output.setValue(res.result)
  output.session.setMode("ace/mode/ocaml");
})