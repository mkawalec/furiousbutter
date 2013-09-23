class Ostrich extends Theme
    @include new CachedAjax()

    constructor: ->
        Ostrich.register @

    render_index: (callback, ctx) ->
        console.log ':D'


ostrich = new Ostrich()
