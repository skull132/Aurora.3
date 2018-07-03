/*
 * Vue.js based ui framework for SS13
 * Made for Aurora, by Karolis K.
 */
import Vue from 'vue'
import upperFirst from 'lodash/upperFirst'
import camelCase from 'lodash/camelCase'

import Store from './store.js'
import './assets/global.scss';

const requireComponent = require.context(
  './components', // The relative path of the components folder
  true, // Whether or not to look in subfolders
  /[A-Za-z]\w+\.vue$/ // The regular expression used to match base component filenames
)

requireComponent.keys().forEach(fileName => {
  const componentConfig = requireComponent(fileName)
  const componentName = upperFirst(
      camelCase(
          // Strip the leading `'./` and extension from the filename
          fileName.replace(/^\.\/(.*)\.\w+$/, '$1')
      )
  )
  Vue.component(
      componentName,
      componentConfig.default || componentConfig
  )
})

Vue.config.productionTip = false

var state = JSON.parse(document.getElementById('initialstate').innerHTML)

Store.loadState(state)

global.receiveUIState = (jsonState) => {
    Store.loadState(JSON.parse(jsonState))
}

global.pushUIState =  function() {
  if (Store.isUpdating) {alert(Store.isUpdating); return}
  var r = new XMLHttpRequest()
  r.open("GET", "?src=" + Store.state.uiref + "&" + Store.getStatePushString(), true);
  r.send()
}

window.setInterval(() => {
  Store.state.wtime += 2
}, 200)

new Vue({
  data: Store.state,
  template: "<div><component v-if='componentName' :is='componentName'/><component v-if='templateString' :is='{template:templateString}'/></div>",
  computed: {
    componentName() {
      if(this.$root.$data.active.charAt(0) != "?") {
        return 'view-' + this.$root.$data.active
      }
    },
    templateString() {
      if(this.$root.$data.active.charAt(0) == "?") {
        return "<div>" + this.$root.$data.active.substr(1) + "</div>"
      }
    }
  },
  watch: {
    state: {
      handler() {
        global.pushUIState()
      },
      deep: true
    }
  }
}).$mount('#app')

if (document.getElementById("header")) {
  new Vue({
    data: Store.state
  }).$mount('#header')
}

if (document.getElementById("dapp")) {
  new Vue({
    data: Store.state,
    template: '<div><h1>Current data of UI:</h1><pre>{{ JSON.stringify(this.$root.$data, null, \'    \') }}</pre></div>'
  }).$mount('#dapp')
}

var lintfail = 1