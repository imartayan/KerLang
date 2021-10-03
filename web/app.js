Split(['#pan-doc', '#pan-editor'], { sizes: [20, 80] })
Split(['#code-editor', '#compiler-output'])

let ace_editor = ace.edit('code-editor')
ace_editor.setTheme('ace/theme/dracula')

let output = ace.edit('compiler-output')
output.setTheme('ace/theme/dracula')
output.setReadOnly(true)

let error_report = document.getElementById('error-report')

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

let fail = () => {
  error_report.innerHTML = '<div class="ko">compilation error</div>'
}

let success = () => {
  error_report.innerHTML = '<div class="ok">compilation succeeded</div>'
}



toC.addEventListener('click', () => {
  try {
    let res = Kerlang.generateC(ace_editor.getValue())
    output.setValue(res.result)
    output.session.setMode("ace/mode/c_cpp");
  } catch {
    fail()
    return
  }
  success()
})

toPY.addEventListener('click', () => {
  try {
    let res = Kerlang.generatePY(ace_editor.getValue())
    output.setValue(res.result)
    output.session.setMode("ace/mode/python")
  } catch {
    fail()
    return;
  }
  success()
})

toML.addEventListener('click', () => {
  try {
    let res = Kerlang.generateML(ace_editor.getValue())
    output.setValue(res.result)
    output.session.setMode("ace/mode/ocaml");
  } catch {
    fail()
    return;
  }
  success()
})