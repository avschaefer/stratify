function find(type, under, element = document.documentElement) {
  const selector = `script[type="${type}"]`
  const tag = element.querySelector(selector)
  if (tag) {
    return Promise.resolve(JSON.parse(tag.textContent))
  } else {
    return Promise.reject(new Error(`Couldn't find ${type} tag under ${under}`))
  }
}

function extract(map) {
  return Promise.all(Object.keys(map).map(id => {
    return import(map[id]).then(module => [id, module])
  }))
}

function register(modules, application) {
  modules.forEach(([id, module]) => {
    if (typeof module.default === "function") {
      const name = identifierForContextKey(id)
      application.register(name, module.default)
    }
  })
}

function identifierForContextKey(key) {
  const logicalName = (key.match(/^(?:\.\/)?(.+)(?:[._]controller\.[jt]s)?$/) || [])[1]
  if (logicalName) {
    return logicalName.replace(/_/g, "-").replace(/\//g, "--")
  }
}

export function eagerLoadControllersFrom(type, under, element = document.documentElement) {
  find(type, under, element).then(extract).then(modules => register(modules, under))
}

export function lazyLoadControllersFrom(type, under, element = document.documentElement) {
  find(type, under, element).then(extract).then(modules => register(modules, under))
}
