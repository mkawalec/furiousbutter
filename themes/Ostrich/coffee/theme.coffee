class Ostrich extends Theme
    constructor: -> Ostrich.register @

    render_index: (ctx, callback) ->
        super ctx, (data) ->
            $('body').html data

    render_post: (post, list) ->
        console.log(post, list)

ostrich = new Ostrich()
