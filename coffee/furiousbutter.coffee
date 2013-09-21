p = palantir {static_prefix: 'static'}
p.templates.parse = (body, context) ->
    compiled = _.template body
    return compiled context

index = (spec={}, that={}) ->
    posts = []

    that.create = -> p.get 'posts/index.txt', (data) ->
        posts_list = data.split('\n')
        _.each _.filter(posts_list, (i) -> i? and i.length > 0),
            _.partial(parse_post, _.partial(post_parsed, posts_list.length))

    parse_post = (callback, filename) ->
        p.get "posts/#{ filename }", (data) ->
            [header, body] = _.filter data.split('---'), (i) -> i.length > 0
            header = parse_header header
            console.log 'body', body
            post_parsed {header: header, body: marked(body)}

    post_parsed = (posts_amount, post) ->
        posts.push posts_amount
        if posts.length == posts_amount
            p.templates.open "themes/#{ spec.theme }/index.html",
                posts, {}, $('body')

    parse_prop = (line) ->
        if not line? then return ''
        return $.trim line[0].split(':')

    parse_header = (header) ->
        return {
            title: parse_prop header.match(/title:.*/i)
            categories: _.each parse_prop(header.match /categories:.*/i).split(','),
                (cat) -> $.trim cat
        }

    return that

settings = {
    theme: 'ostrig'
}

blog = index settings
blog.create()
