class Cache
    @cache = {}
    @dirty = false
    @storage_key = 'FuriousButter'

    constructor: ->
        if window.localStorage?
            setInterval(@persist, 5000)
            if localStorage[Cache.storage_key]?
                Cache.cache = JSON.parse localStorage[Cache.storage_key]

    get: (key) ->
        if _.has(Cache.cache, key)
            if @timeout(key) then delete Cache.cache[key]
            else return Cache.cache[key].payload
        return undefined

    set: (key, value, timeout=3600) ->
        Cache.cache[key] = {
            expires: (new Date()).getTime() + 1000 * timeout
            payload: value
        }
        Cache.dirty = true
        return key

    timeout: (key) ->
        if (new Date()).getTime() > Cache.cache[key].expires then return true
        return false

    persist: ->
        if not Cache.dirty then return
        window.localStorage[Cache.storage_key] = JSON.stringify Cache.cache

        Cache.dirty = false

class CachedAjax
    cache: new Cache

    ajax: (params, timeout) =>
        if @cache.get(params.url) then params.success @cache.get(params.url)
        else
            params.success = ((callback) => (data) =>
                @cache.set(params.url, data, timeout)
                callback data
            )(params.success)

            $.ajax params

    get: (url, callback=( -> ), timeout) =>
        @ajax {url: url, type: 'GET', success: callback}, timeout

    post: (url, data, callback=( -> ), timeout) =>
        @ajax {url: url, data: data, type: 'POST', success: callback}, timeout

    put: (url, data, callback=( -> ), timeout) =>
        @ajax {url: url, data: data, type: 'PUT', success: callback}, timeout

    delete: (url, callback=( -> ), timeout) =>
        @ajax {url: url, type: 'DELETE', success: callback}, timeout

class Helpers
    pull_params: (route) ->
        addr = route.split('?')[0]
        params = {}

        if route.split('?').length > 1
            raw_params = route.split('?')[1].split('&')
            params = _.foldl(raw_params, (memo, param) ->
                memo[decodeURIComponent(param.split('=')[0])] = \
                    decodeURIComponent(param.split('=')[1])
                return memo
            , {})
        return [addr, params]

    add_params: (route, params) ->
        _.each params, (value, key) ->
            if '?' not in route then route += '?'
            else route += '&'

            route += "#{ encodeURIComponent key }=#{ encodeURIComponent value.toString() }"
        return route

class Router extends Helpers
    @routes: {}

    @route: (route, fn) ->
        Router.routes[route] = fn
        return fn

    @goto: (route, params...) ->
        [route, route_params] = @pull_params route
        params = _.foldl(params, (memo, value, key) ->
            memo[key] = value
            return memo
        , route_params)

        window.location.hash = "##{ @add_params route, params }"

    @hashchange: (e) ->
        e.preventDefault()

        [route, params] = @pull_params location.hash.slice(1)
        if _.has(Router.routes, route) then Router.routes[route](params)

class Index extends CachedAjax
    @renderers: {
        native: (context, data) ->
            compiled = _.template body
            return compiled context
    }
    @themes: {}
    posts: []

    parse_data: (callback=( -> ), filename) =>
        @get "posts/#{ filename }", (data) =>
            [header, body] = _.filter data.split('---'), (i) -> i.length > 0
            header = @parse_header header
            callback {header: header, body: marked(body)}

    post_parsed: (post) =>

    parse_header: (header) ->
        return _.foldl(_.filter(header.split('\n'), (i) -> i.length > 0),
            (memo, line) ->
                prop = _.first line.split(':')
                memo[prop] = $.trim line.split(':')[1]
                if memo[prop].indexOf(',') != -1
                    memo[prop] = _.each memo[prop].split(','), (i) -> $.trim i
                return memo
        , {})

    constructor: (@spec) ->
        @get 'posts/index.txt', (data) =>
            @posts_list = _.filter data.split('\n'), (i) -> i? and i.length > 0
            _.each @posts_list, _.partial(@parse_data, @post_parsed)


settings = {
    theme: 'ostrich'
}

blog = new Index settings
