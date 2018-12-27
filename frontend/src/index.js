'use strict'

require('./styles.scss')

const {Elm} = require('./Main')

const storageKey = 'store'
const flags = localStorage.getItem(storageKey)
let app = Elm.Main.init({flags: flags})

app.ports.storeCache.subscribe(function (val) {
  if (val === null) {
    localStorage.removeItem(storageKey)
  } else {
    localStorage.setItem(storageKey, JSON.stringify(val))
  }

  // Report that the new session was stored succesfully.
  setTimeout(function () { app.ports.onStoreChange.send(val) }, 0)
})

// Whenever localStorage changes in another tab, report it if necessary.
window.addEventListener('storage', function (event) {
  if (event.storageArea === localStorage && event.key === storageKey) {
    app.ports.onStoreChange.send(event.newValue)
  }
}, false)

app.ports.toJs.subscribe(data => {
  console.log(data)
})
