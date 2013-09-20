######################################
##                                  ##
## Copyright Michal Kawalec, 2013   ##
##                                  ##
##                                  ##
## Ten kod dedykuję Ewci <3         ##
##                                  ##
######################################

stack = ->
    that = {}

    store = []

    that.push = (item) ->
        store.push(item)

    that.pop = ->
        if store.length == 0
            return undefined

        item = store[store.length-1]
        store.splice(store.length-1, 1)

        return item

    return that

init = (initiator, public_initiator, spec, inherited) ->
    _helpers = helpers()

    new_id = _helpers.random_string()
    if (not initiator.prototype.call_ids?) and (not initiator.prototype.callers?)
        initiator.prototype = {}

    initiator.prototype.call_ids = initiator.prototype.call_ids ? []
    initiator.prototype.call_ids.push new_id
    initiator.prototype.call_that = public_initiator

    if (not inherited.prototype.callers?) and (not inherited.prototype.call_ids?)
        inherited.prototype = {}
    inherited.prototype.callers = inherited.prototype.callers ? []
    inherited.prototype.callers.push(new_id)
    
    if inherited.prototype.call_ids?
        if (_.intersection initiator.prototype.callers, inherited.prototype.call_ids).length > 0
            return inherited.prototype.call_that

    return inherited spec

singleton = (fn) ->
    return () ->
        that = arguments[1] ? {}

        if singleton.prototype.cached? and \
           singleton.prototype.cached[fn]?
                return _.extend {}, singleton.prototype.cached[fn], that

        if not singleton.prototype.cached?
            singleton.prototype = {}
            singleton.prototype.cached = {}
        singleton.prototype.cached[fn] = fn.apply(null, arguments)

        return _.extend {}, singleton.prototype.cached[fn], that

helpers = singleton((spec={}) ->
    that = {}

    chars = 'abcdefghijklmnoprstuwqxyzABCDEFGHIJKLMNOPRSTUWQXYZ0123456789'

    _props = ['id', 'data-source', 'data-actions', 
        'data-shown_property', 'data-binding',
        'data-params', 'data-button', 'data-removable']

    that.notify_success = (where, change_color='#bfdd85') ->
        # Animate background to the green and back to indicate
        # that an action has succeeded. In its current form
        # required jqueryui to work

        color = where.css 'background-color'
        where.animate({'background-color': change_color}).animate({
            'background-color': color})
   
    that.clone = (element) ->
        tag_name = element.tagName.lower()

        clone = $("<div/>", {
            class: tag_name
            'data-tag': tag_name
        })

        _.each _props, (prop) ->
            $(clone).attr(prop, $(element).attr(prop))
        $(element).replaceWith clone
        return clone

    that.is_number = (data) ->
        return not isNaN(parseFloat(data)) and isFinite(data)

    that.random_string = (length=12) ->
        ret = []
        for i in [0...length]
            ret.push chars[Math.floor(chars.length*Math.random())]
        return ret.join ''

    that.deep_copy = (obj) ->
        if $.isArray(obj)
            ret = []
            for el in obj
                ret.push(that.deep_copy(el))
            return ret
        else if $.isPlainObject(obj)
            ret = {}
            keys = _.keys(obj)
            if obj.__keys?
                keys = keys.concat obj.__keys

            _.each keys, (key) ->
                value = obj[key]
                if typeof value == 'function'
                    ret[key] = value
                else
                    ret[key] = that.deep_copy value

            return ret

        return obj

    # TODO: Deal with parameter arrays ie. 
    # pull ?arr[]=first&arr[]=second into
    # arr = ['first', 'second']
    that.pull_params = (route) ->
        addr = route.split('?')[0]
        params = {}

        if route.split('?').length > 1
            raw_params = route.split('?')[1].split('&')
            for param in raw_params
                params[decodeURIComponent(param.split('=')[0])] = \
                    decodeURIComponent(param.split('=')[1])

        return [addr, params]

    that.add_params = (route, params) ->
        if Object.prototype.toString.call(params) == '[object Array]' \
            and params.length == 1 and typeof params[0] == 'object'
                params = params[0]

        if Object.prototype.toString.call(params) == '[object Array]'
            for param,i in params
                if i == 0 and '?' not in route
                    route += '?'
                else
                    route += '&'
                route += 'param'+i+'='+encodeURIComponent(param)
        else if typeof params == 'object'
            i = 0
            for key, value of params
                if i == 0 and '?' not in route
                    route += '?'
                else
                    route += '&'
                route += "#{ encodeURIComponent key }=#{ encodeURIComponent value.toString() }"
                i += 1

        return route

    that.delay = (fn) ->
        setTimeout(fn, 0)

    that.parse_methods = (to_parse) ->
        if not to_parse?
            return []

        parsed = []

        for validator in to_parse.split(';')
            split = validator.split('(')
            name = $.trim split[0]

            # The dictionary on position 1 holds named params
            ret_params = [{}]

            if split.length > 1
                split[1] = $.trim split[1]
                params = split[1].slice(0, split[1].length-1)
                for param in params.split(',')
                    param = ($.trim(param)).split('=')
                    if param.length > 1
                        tmp = {}
                        tmp[param[0]] = param[1]
                        _.extend ret_params[0], tmp
                    else
                        ret_params.push(param[0])

            parsed.push {method: name, params: ret_params}

        return parsed

    return that
)

gettext = singleton((spec={}, that={}) ->
    if spec[0]?
        spec = spec[0]

    lang = spec.lang ? ($('html').attr('lang') ? 'en')
    lang = if lang.length == 0 then 'en' else lang
    default_lang = spec.default_lang ? 'en'

    static_prefix = spec.static_prefix ? ''
    translations_url = spec.translations_url ? "#{ spec.base_url+static_prefix }translations/"
    if translations_url.indexOf('://') == -1
        translations_url = spec.base_url + translations_url

    translations = {}

    that.gettext = (text, new_lang=lang) ->
        if translations[new_lang] == undefined
            if new_lang != default_lang
                getlang(new_lang)
            else
                return text

        if translations[new_lang] == null
            return text

        if not translations[new_lang][text]?
            return text
        return translations[new_lang][text]

    getlang = (to_get) ->
        p.open {
            url: "#{ translations_url+to_get }.json"
            async: false
            success: (data) ->
                try
                    translations[to_get] = JSON.parse data
                catch e
                    if not e instanceof SyntaxError then throw e
                    translations[to_get] = data
            error: (data) ->
                if data.status == 404
                    translations[to_get] = null
            palantir_timeout: 3600*48
        }

    spec = _.extend spec, {__inner: true}
    inheriter = _.partial init, gettext, that, spec
    p = inheriter palantir

    return that
)

notifier = (spec={}, that={}) ->
    _helpers = helpers(spec)

    placeholder = $('#alerts')

    that.notify = (req_data) ->
        if not messages.get_message(req_data)?
            if messages.get_code_message(req_data.status)?
                show_message(messages.get_code_message, req_data.status)
                return
            return

        show_message(messages.get_message, req_data)

    that.extend_code_messages = (data) ->
        messages.extend_code_messages data

    that.extend_messages = (data) ->
        messages.extend_messages data
          
    show_message = (fn, key) ->
        # We don't want to show the 'unspecified' errors,
        # because we want to hide errors from the users :D
        if key == 0 then return

        alert = $('<div/>', {
            class: "alert alert-#{ fn(key).type }"
        })

        close_button = $('<button/>', {
            class: 'alert-close'
            html: $('<i/>', {class: 'alert-close icon-remove'})
        })

        message_wrapper = $('<div/>', {
            class: 'message_wrapper'
            text: fn(key).message
        })

        alert.append close_button
        alert.append message_wrapper
        alert.hide()

        placeholder.append alert
        alert.show 'slide'

    spec = _.extend spec, {__inner: true}
    inheriter = _.partial init, notifier, that, spec
    p = inheriter(palantir)
    __ = p.gettext.gettext

    messages = (singleton ->
        code_messages = {
            500: {
                type: 'error'
                message: __ 'An internal server error has occured'
            }
            0: {
                type: 'error'
                message: __ 'An unspecified communication error has occured'
            }
        }

        messages = {
            1: {
                type: 'success'
                message: __ 'The action has succeeded'
            }
        }

        that = {}

        that.get_code_message = (code) ->
            return code_messages[code]

        that.get_message = (code) ->
            return messages[code]

        that.extend_code_messages = (data) ->
            _.extend code_messages, data

        that.extend_messages = (data) ->
            _.extend messages, data

        return that
    )()

    return that

template = (spec={}, that={}) ->
    if spec[0]?
        spec = spec[0]

    trans_regex = /{%(.*?)%}/g
    spec_regex = /{{(.*?)}}/g

    _libs = {}
    _.extend _libs, helpers(spec)

    static_prefix = spec.static_prefix ? ''
    template_url = spec.template_url ? "#{ spec.base_url+static_prefix }templates/"
    if template_url.indexOf('://') == -1
        template_url = spec.base_url + template_url

    if spec.model_url? and spec.model_url.indexOf('://') == -1
        spec.model_url = spec.base_url + spec.model_url

    translate = (_, text) ->
        return __ $.trim text

    get_spec = (context) ->
                    (_, text) ->
                        trimmed = $.trim text
                        return context[trimmed]

    add_element = (element, data) ->
        $(element).parent().append(
            "<button class='btn btn-success add'>"+\
            "<i class='icon-plus'></i></button>")
        add_btn = $(element).siblings '.add'

        $(add_btn).on 'click', (e) ->
            e.preventDefault()
            modal = new Modal __ 'Add'
            modal.add_form()

            for field in _.keys data.data
                switch data.data[field]
                    when 'str'
                        modal.add_field field
                    when 'unicode'
                        modal.add_field field
                    when 'int'
                        attrs = {'data-parser': 'Decimal'}
                        modal.add_field field, attrs
                    when 'Decimal'
                        attrs = {'data-parser': 'Decimal'}
                        modal.add_field field, attrs

            btn = modal.add_button 'info', __ 'Add'
            $(btn).on 'click', (e) ->
                data = {}
                for field in $(modal.get()).find('.form-horizontal').find('input')
                    data[$(field).attr('data-binding')] = $.trim field.value

                _libs.open {
                    url: $(element).attr('data-source')
                    type: 'POST'
                    data: data
                    success: (data) ->
                        modal.hide()
                        that.set_details element, false
                }

            modal.show()

    that.parse = spec.template_parser ? (body, context=spec) ->
        body = body.replace trans_regex, translate
        body = body.replace spec_regex, get_spec(context)

        return body

    parse_binds = (element) ->
        data = {}
        form = element.closest('form')
        if form.length == 0
            form = element.closest('.form')

        if form.length > 0
            for el in form.find '[data-binding]'
                el = $(el)
                value = el[0].value ? el.text()

                data[el.attr 'data-binding' ] = value

        return data

    that.bind = (where) ->
        _.each $(where).find('[data-source]'), (element) ->
            if $(element).attr('data-actions')?
                actions = JSON.parse $(element).attr('data-actions')
            that.set_details element, null, actions

        for element in $(where).find("[data-wysiwyg='true']")
            editor = new nicEditor()
            element = $(element)

            editor.panelInstance element.attr('id')

            # Make the validators observe the correct field
            inner_area = (nicEditors.findEditor element.attr('id')).\
                getElm()
            $(inner_area).attr('data-validators', 
                element.attr('data-validators'))
            element.attr('data-validators', '')
            $(inner_area).css 'min-height', '320px'

    that.process_click = (e) ->
        element = $(e.target).closest('[data-click]')
        _helpers.delay ->
            if element.attr('data-prevent_default') == 'true'
                return

            data = parse_binds element

            if element.attr('data-silent') != 'false'
                data.silent = true

            if data.silent != true
                _validators.hide()

            _libs.goto element.attr('data-click'), data

    set_object = (element, actions, data) ->
        # Sets the custom tag contents
        contents = $(element).html()
        $(element).html('')
        if contents == 'null'
            return $(element).html(__ 'No category')

        data_tag = $(element).attr('data-tag')
        if data_tag?
            if tag_renderers.get(data_tag)?
                tag_renderers.get(data_tag) element, data
            else tag_renderers.get('div') element, data
        else
            if not element.tagName?
                tag_renderers.get('div') element, data, contents
            else
                tag_name = element.tagName.lower()
                if tag_renderers.get(tag_name)?
                    tag_renderers.get(tag_name) element, data
                else tag_renderers.get('div') element, data

        if actions? and actions.add
            _libs.open {
                url: $(element).attr('data-source') + 'spec/'
                success: (data) ->
                    add_element element, data 
            }

    that.set_details = (element, caching=true, actions) ->
        if not $(element).attr('data-source')? or \
            $(element).attr('data-source').length == 0
                set_object element

        _libs.open {
            url: $(element).attr('data-source')
            caching: caching
            success: _.partial set_object, element, actions
        }

    tag_renderers = (singleton ->
        _that = {}

        _renderers = {
            select: (element, data) ->
                for el in data.data
                    $(element).append($("<option/>", {
                        value: el.string_id
                        text: el[$(element).attr('data-shown_property')]
                    }))

            div: (element, data, contents) ->
                for el in data.data
                    if el.string_id == contents
                        $(element).html el[$(element).attr('data-binding')]
                        break

            checklist: (element, data) ->
                element = _helpers.clone(element)

                $(element).on 'change', 'input', (e) ->
                    selected = []
                    for el in $(e.delegateTarget).\
                        find("input[type='checkbox']:checked")
                            selected.push(el.value)

                    $(e.delegateTarget).\
                        attr('data-value', JSON.stringify(selected))

                # For all elements
                for el in data.data
                    id = _libs.random_string()

                    checkbox_group = $('<div/>', {
                        class: 'checkbox-group'
                    })
                    blah = checkbox_group.append($("<input/>", {
                        type: 'checkbox'
                        value: el.string_id
                        id: id
                    }))
                    checkbox_group.append($('<label/>', {
                        for: id
                        text: el[$(element).attr('data-shown_property')]
                    }))

                    element.append(checkbox_group)
        }

        _that.get = (renderer) ->
            return _renderers[renderer]

        _that.extend = (to_extend) ->
            _.extend _renderers, to_extend

        return _that
    )()

    fill = (where, url, string_id) ->
        data_source = _model.init {url: url}

        data_source.get ((data) ->
            data_source.keys (keys) ->
                for key in keys
                    col = $("[data-binding='#{ key }']")
                    if col.attr('data-wysiwyg') != 'true'
                        col.val data[key]
                    else
                        editor = nicEditors.findEditor col.attr('id')
                        editor.setContent data[key]
        ), {id: string_id}

    that.open = (name, context={}, params={}, callback=( -> )) ->
        params.action = params.action ? 'add'
        context = _.extend(_.extend(params, spec), context)
        ctx = _helpers.deep_copy context

        _libs.open {
            url: template_url + name 
            success: (data) ->
                data = that.parse data, ctx

                if params.where?
                    if params.add_action?
                        params.where[params.add_action] data
                    else if params.append == true
                        params.where.append data
                    else if params.prepend == true
                        params.where.prepend data
                    else
                        params.where.html data

                    if params.string_id?
                        # Passing string_id as parameter
                        # is deprecated and not suggested
                        _.each params.where.find('[data-click]'), (el) ->
                            route = _helpers.add_params $(el).attr('data-click'),
                                {string_id: params.string_id}
                            $(el).attr('data-click', route)

                    that.bind params.where

                    if params.action == 'edit'
                        fill params.where, params.url, params.string_id

                    _validators.discover params.where
                callback.call ctx, data
            tout: 3600*48
        }

    that.extend_renderers = (extensions) ->
        tag_renderers.extend extensions

    that.extend_renderers spec.tag_renderers
    
    spec = _.extend spec, {__inner: true}
    inheriter = _.partial init, template, that, spec
    _.extend _libs, inheriter palantir
    _helpers = inheriter helpers
    _notifier = inheriter notifier 
    _model = inheriter model
    _validators = inheriter validators
    __ = inheriter(gettext).gettext

    return that

cache = singleton((spec={}) ->
    that = {}
    _helpers = helpers(spec)

    timeout = spec.timeout ? 1800

    # A cache object structure:
    # obj = {
    #   expires: int
    #   payload: Object
    # }
    _cache = {}
    dirty = false
    localstorage_key = spec.localstorage_key ? 'palantir_cache'

    has_timeout = (data) ->
        now = (new Date()).getTime()

        if now > data.expires
            return true
        return false

    that.get = (key) ->
        if _cache[key]
            if has_timeout _cache[key]
                that.delete key
            else if _cache[key] != undefined
                return _cache[key].payload
        return undefined

    that.set = (key, value, new_timeout=timeout) ->
        payload = {
            expires: (new Date()).getTime()+1000*new_timeout
            payload: _helpers.deep_copy value
        }
        _cache[key] = payload
        dirty = true

        return key

    that.delete = (key) ->
        delete _cache[key]
        return undefined

    that.genkey = (data) ->
        # Generates keys for internal-use cache
        to_join = ["__internal", "type:#{ data.type }", "url:#{ data.url }",
            "data: #{ JSON.stringify(data.data) }"]
        return to_join.join ';'

    that.delall = (url) ->
        # Delete all entries in the cache that relate to the
        # provided url (either contain the index of items 
        # represented by the url or contain the item referenced
        # by the url)

        if url.length == 0 then return

        model_url = url
        if url[url.length-1] != '/'
            index = url.split('').reverse().join('').indexOf('/')
            model_url = url.slice(0, url.length-index)

        searched = "url:#{ url }"
        searched_model = "url:#{ model_url }"
        for key,value of _cache
            if key.indexOf(searched) != -1 or \
                key.indexOf(searched_model) != -1
                    dirty = true
                    delete _cache[key]

    that.clear = ->
        # Remove EVERYTHING from the cache, including
        # the localCache store
        _cache = {}
        localStorage[localstorage_key] = JSON.stringify _cache

    prune_old = (percent=20) ->
        now = (new Date()).getTime()
        keys = []

        for key, value of _cache
            keys.push({key: key, delta_t: value.expires-now})

        keys = _.sortBy keys, (item) -> item.delta_t

        for i in [0...(keys.length*percent/100)]
            delete _cache[keys[i].key]

    that.persist = (force=false)->
        if dirty == true or force
            try
                localStorage[localstorage_key] = JSON.stringify _cache
                dirty = false
            catch e
                if e.name == 'QuotaExceededError'
                    prune_old()
                    that.persist()

    # Periodiacally backup to the locaCache to provide
    # data persistence between reloads
    backup_job = setInterval(that.persist, 1000)

    # Load from the localStorage and set up stuff
    setTimeout((() ->
        if not localStorage?
            window.clearInterval backup_job
            return

        if localStorage[localstorage_key]?
            _cache = JSON.parse(localStorage[localstorage_key])
    ), 0)

    return that
)

validators = (spec={}, that={}) ->
    _helpers = helpers spec

    # The fields managed by this code
    managed = {}
    # The submit handlers
    handlers = {}
    # Validations error display methods
    display_methods = (singleton ->
        _that = {}
        _methods = {}

        _that.get = (id) ->
            return _methods[id]

        _that.all = ->
            return _methods

        _that.extend = (to_extend, overwrite=false) ->
            if not overwrite 
                extend_with = _.omit(to_extend, _.keys(_methods)) 
            else 
                extend_with = to_extend

            _.extend(_methods, extend_with)

        return _that
    )()

    validators_db = (singleton ->
        _that = {}
        _validators = {
            length: (object, kwargs, args...) ->
                # Checks if the length of object value 
                # is between the given bounds

                kwargs.min = kwargs.min ? (args[0] ? 0)
                kwargs.max = kwargs.max ? (args[1] ? Number.MAX_VALUE)
                errors = []

                value = if object.value? then object.value else $(object).text()
                length = $.trim(value).length

                # The following is oddly formatted thanks to babel being stupid
                if length < kwargs.min
                    errors.push(__("The input of length ") + length + \
                        __(' you entered is too short. The minimum length is ')+ \
                        kwargs.min )
                if length > kwargs.max
                    errors.push(__("The input of length ") + length + \
                        __(' you entered is too long. The maximum length is ')+ \
                        kwargs.max )
                return errors

            email: (object, kwargs, args...) ->
                # Checks if the value of a field is an email

                regex = kwargs.regex ? \
                    /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
                if not $.trim(object.value).match regex
                    return [__('The email you entered is incorrect')]
                return null

            url: (object, kwargs) ->
                # Checks if the field contains a url addres
                regex = kwargs.regex ? \
                    /^[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?$/ 
                if not $.trim(object.value).match regex
                    return [__('The url you entered is incorrect')]
                return null

            required: (object) ->
                # Something needs to be entered in the field

                value = if object.value? then object.value else $(object).text()
                if $.trim(value).length == 0
                    return [__('This field is obligatory')]
                return null

            decimal: (object) ->
                # Brings the number to a python-friendly decimal form
                # (if possible) and tests if the value can even be 
                # interpreted as a number
                
                value = $.trim(object.value).replace ',', '.'
                value = value.replace ' ', ''

                decimal_regex = /^[0-9]+(\.[0-9]+)?$/
                if decimal_regex.test(value) == false
                    return [__('This doesn\'t look like a number')]

                if object.value != value
                    object.value = value
                return null

            not: (object, kwargs, args...) ->
                # Checks if the object value is the same as one of the provided
                # values, fails if it is

                value = if object.value? then object.value else $(object).text()
                value = $.trim value

                for arg in args
                    if value == arg
                        return [__("The value must be different then \'#{ value }\'")]
                return null

            same_as: (object, kwargs, args...) ->
                # Requires the field to be the same as all of the 
                # fields provided as args (or kwargs.field)

                get_value = (field) ->
                    field = $(field)
                    value = if field[0].value? then field[0].value else field.text()
                    return $.trim value

                value = get_value object

                if kwargs.field?
                    args.push(kwargs.field)

                errors = []
                for field in args    
                    second_value = get_value field

                    if second_value != value
                        errors.push __("The value must be the same as the value in #{ field }")
                if errors.length > 0
                    return errors
                return null
        }

        _that.apply = (validator, params) ->
            if _validators[validator] == undefined
                return undefined
            return _validators[validator].apply null, params

        _that.extend = (to_extend) ->
            _.extend _validators, to_extend

        _that.get = ->
            return _validators
        return _that
    )()

    that.discover = (where=spec.placeholder) ->
        for form in where.find('.form')
            form = $(form)
            if not form.attr('data-validation_id')?
                form.attr 'data-validation_id', _helpers.random_string()
            fields = {}

            for field in form.find('[data-validators]')
                field = $(field)
                field.attr 'data-validation_id', _helpers.random_string()
                field_validators = []
                parsers = []

                for validator in parse_validators(field[0], field.attr('data-validators'))
                    field_validators.push validator
                for parser in parse_validators(field[0], field.attr('data-parsers'))
                    parsers.push parser

                methods = {
                    validators: field_validators
                    parsers: parsers
                }
                fields[field.attr('data-validation_id')] = methods
            
            for handler in form.find("[data-submit='true']")
                handler = $(handler)
                if not handler.attr('data-validation_id')?
                    handler.attr 'data-validation_id', _helpers.random_string()

                handlers[handler.attr('data-validation_id')] = \
                    form.attr('data-validation_id')

            form.on 'keyup', 'input,textarea,.nicEdit-main', field_changed

            fields.inhibited = true
            managed[form.attr('data-validation_id')] = fields

            form.on 'click', "[data-submit='true']", submit_handler
            form.on 'submit', submit_event_handler

    that.bind_to_field = (field, validators_string, fire=false) ->
        field_validators = []
        for validator in parse_validators(field[0], validators_string)
            field_validators.push validator

        form = field.closest('.form')
        if form.length == 0
            form = field.parent()

        if not form.attr('data-validation_id')?
            form.attr 'data-validation_id', _helpers.random_string()

        if not field.attr('data-valiation_id')?
            field.attr 'data-valiation_id', _helpers.random_string()

        form_id = form.attr('data-validation_id')
        field_id = field.attr('data-validation_id')
        if managed[form_id]?
            field_obj = managed[form_id][field_id]
            if field_obj?
                # We don't want to append the same validator multiple
                # times
                field_validators = _.reject field_validators, (item) ->
                    for validator in field_obj.validators
                        if _.isEqual(validator, item)
                                return true
                    return false

                field_obj.validators = field_obj.validators.concat(field_validators)
            else
                managed[form_id][field_id] = {
                    validators: field_validators
                    parsers: []
                }
        else
            managed[form_id] = {}
            managed[form_id][field_id] = {
                validators: field_validators
                parsers: []
            }

        form.off 'keyup'
        form.on 'keyup', 'input,textarea,.nicEdit-main', field_changed

        if fire == true
            errors = []
            errors = errors.concat(test_field field_id, managed[form_id][field_id])
            if errors.length > 0
                display_errors errors

    field_changed = (e) ->
        # Handles rechecking the field if its contents changed
        validation_id = $(e.target).attr('data-validation_id')
        for id,fields of managed
            if fields.inhibited == true
                continue

            if fields[validation_id] != undefined
                errors = test managed[id], validation_id
                return display_errors errors, validation_id

    display_errors = (errors, current_id) ->
        for name,method of display_methods.all()
            method.create errors, current_id

    submit_handler = (e) ->
        id = handlers[$(e.target).attr('data-validation_id')]
        if not id? then return

        errors = test managed[id]
        if errors.length > 0
            $(e.target).attr('data-prevent_default', 'true')
            display_errors errors
            managed[id].inhibited = false
        else
            $(e.target).attr('data-prevent_default', 'false')

    submit_event_handler = (e) ->
        e.preventDefault()
        submit_handler e

    that.init = that.discover

    that.extend = (to_extend) ->
        validators_db.extend to_extend

    that.extend_display_methods = (methods, overwrite) ->
        display_methods.extend methods, overwrite

    that.test = ->
        errors = {}
        for id,fields of managed
            errors[id] = test fields
        return errors

    that.hide = ->
        # Enforce hiding of all validators
        for name,method of display_methods.all()
            method.hide()

    spec = _.extend spec, {__inner: true}
    inheriter = _.partial init, validators, that, spec
    p = inheriter palantir

    __ = p.gettext.gettext

    parse_validators = (field, to_parse) ->
        methods = _helpers.parse_methods to_parse
        for method in methods
            method.params.unshift field

        return methods

    test = (fields, current_id) ->
        errors = []
        for id,methods of fields
            if id == 'inhibited'
                continue

            errors.push.apply(errors, test_field(id, methods, current_id))
        return errors

    test_field = (id, methods, current_id) ->           
        errors = []

        # The parsers are applied before validators.
        # We are not interested in their output
        for parser in methods.parsers
            validators_db.apply parser.method, parser.params

        errors_added = []
        for validator in methods.validators
            err = validators_db.apply validator.method, validator.params
            if err? and err.length > 0
                if not current_id? or current_id == id
                    $(validator.params[0]).addClass 'validation-error'
                    errors_added.push validator.params[0]
                errors.push {
                    field: id
                    errors: err
                }
            else if (not current_id? or current_id == id) and \
                     not _.contains(errors_added, validator.params[0])
                $(validator.params[0]).removeClass 'validation-error'

        return errors

    return that
        
model = (spec={}, that={}) ->
    autosubmit = spec.autosubmit ? false

    last_params = null
    data_def = null
    managed = []

    # Subsequent ids when called with more
    steps = []
    step_index = -1

    created_models = (singleton ->
        _that = {}
        _models = []

        _that.add = (new_model) ->
            _models.push new_model

        _that.get = ->
            return _models
        return _that
    )()

    that.get = (callback=( -> ), params={}, error_callback=( -> )) ->
        url = spec.url
        if params.id?
            url += params.id
            delete params.id

        that.keys -> 
            p.open {
                url: url
                data: params
                success: (data) ->
                    ret = []
                    if Object.prototype.toString.call(data.data) == '[object Array]'
                        for obj in data.data
                            ret.push makeobj obj
                    else
                        ret = makeobj data.data

                    managed.push.apply(managed, ret)

                    other_params = {}
                    for key,value of data
                        if key != 'data'
                            other_params[key] = value

                    callback ret, other_params
                error: error_callback
                palantir_timeout: 60*10
            }

    that.more = (callback=( -> ), params=last_params) ->
        if step_index > -1
            params.after = steps[step_index]
        else if params.after?
            delete params.after

        saver = ->
            if step_index+1 == steps.length
                last_arg = _.last arguments[0]
                steps.push last_arg[spec.id]
            step_index += 1

            callback arguments

        that.get saver, last_params

    that.geturl = ->
        return spec.url

    that.less = (callback=( -> ), params={}) ->
        if step_index < 1 and params.after?
            delete params.after
        else if step_index > 0
            params.after = steps[step_index-2]

        saver = ->
            step_index -= 1
            callback arguments

        that.get saver, params

    that.submit = (callback=( -> )) ->
        for el in (_.filter managed, (item) -> if item? then true else false)
            if el.__dirty == true
                el.__submit callback

    that.submit_all = (callback=( -> )) ->
        for model in created_models.get()
            model.submit callback

    that.delete = (object, callback=( -> )) ->
        object.__delete callback

    that._all_models = ->
        return created_models.get()

    that.new = (callback=( -> )) ->
        that.keys ->
            new_def = _helpers.deep_copy(data_def)
            console.log new_def
            for key, value of new_def
                new_def[key] = undefined
            ret = makeobj(new_def, true)

            managed.push(ret)

            callback ret

    that.keys = (callback=( -> )) ->
        p.open {
            url: spec.url + 'spec/'
            palantir_timeout: 3600*24
            success: (data) ->
                data_def = normalize data.data
                callback _.keys data.data
        }

    that.init = (params) ->
        new_spec = _helpers.deep_copy spec
        new_spec.id = params.id ? 'string_id'
        new_spec.url = params.url

        if new_spec.url.indexOf('://') == -1
            new_spec.url = new_spec.base_url + new_spec.url
        if new_spec.url[new_spec.url.length-1] != '/'
            new_spec.url += '/'

        created_models.add that

        return model new_spec

    makeobj = (raw_object, dirty=false) ->
        ret = {}
        deleted = false

        for prop,value of raw_object
            if (typeof value == 'object' and value != null) or \
               typeof value == 'function'
                ret[prop] = value
                continue

            ((prop) ->
                set_value = value
                Object.defineProperty(ret, prop, {
                    set: (new_value) ->
                        if prop == spec.id and set_value?
                            throw {
                                type: 'ValueError'
                                message: 'You are trying to set '+\
                                    'the id value which was already set'
                            }
                        check_deletion(ret)

                        if new_value != set_value
                            ret.__dirty = true
                        set_value = new_value
                    get: ->
                        check_deletion(ret)
                        return set_value
                })
            )(prop)

        Object.defineProperty(ret, '__dirty', {
            get: -> dirty
            set: (value) -> dirty = value
        })
        Object.defineProperty(ret, '__deleted', {
            get: -> deleted
            set: (value) -> deleted = value
        })
        Object.defineProperty(ret, '__keys', {
            get: -> _.keys(data_def).concat spec.id
        })

        ret['__submit'] = (callback=( -> ), force=false) ->
            if ret.__dirty == false and not force
                return
            check_deletion(ret)

            that.keys (keys) ->
                data = {}

                # Persist any keys
                for key in keys
                    data[key] = ret[key]

                # But also persist all 'non-special' properties of the
                # data object
                res = _.foldl ret, ((memo, value, key) ->
                    if key.slice(0, 2) != '__' and typeof value != 'function'
                        memo[key] = value
                    return memo
                ), {}
                data = _.extend data, res

                data = {data: JSON.stringify data}

                req_type = if ret.string_id? then 'PUT' else 'POST'
                url = spec.url

                if req_type == 'PUT'
                    url += ret[spec.id]

                p.open {
                    url: url
                    data: data
                    type: req_type
                    success: (data) ->
                        for key, value of data.data
                            console.log key, value
                            try
                                ret[key] = value
                            catch e
                                continue

                        ret.__dirty = false

                        callback()
                    error: validate_failed(callback)
                }

        ret['__delete'] = (callback=( -> )) ->
            check_deletion(ret)

            # Do not delete on a server
            # if the object hasn't been persisted yet
            if not ret[spec.id]?
                delete_object ret
                return

            p.open {
                url: spec.url + ret[spec.id]
                type: 'DELETE'
                success: (data) ->
                    delete_object ret
                    callback()
                error: callback
            }

        return ret

    delete_object = (object) ->
        object.__deleted = true

        for el,i in managed
            if el == object
                # Splice is not used for performance reasons
                managed[i] = undefined
                break

        object = undefined

    validate_failed = (callback=( -> )) ->
        (data) ->
            try
                data = JSON.parse data.responseText
            catch e 
                if e instanceof SyntaxError then return callback data
                else throw e

            # Validates the failed fields, if this is what the server
            # wants.
            if not data.status? or data.status != 'fieldError'
                return
            if data.field?
                _validators.bind_to_field($("[data-binding='#{ data.field }']"), data.validators, true)

            # Let's call the callback now, with the data
            callback data

            # TODO:
            # accept a list of fields & validators

    check_deletion = (obj) ->
        if not obj? or obj.__deleted == true
            throw { 
                type: 'DeletedError'
                message: 'The object doesn\'t exist any more'
            }


    normalize = (data) ->
        for key, value of data
            if value == 'unicode' or value == 'str' or value == 'text'
                data[key] = 'string'
            if value == 'int' or value == 'decimal'
                data[key] = 'number'

        data[spec.id] = 'string'
        return data

    spec = _.extend spec, {__inner: true}
    inheriter = _.partial init, model, that, spec
    p = inheriter palantir
    _helpers = inheriter helpers
    _validators = inheriter validators

    return that

palantir = (spec={}, that={}) ->
    if spec[0]?
        spec = spec[0]

    # Magic generating the base url for the app
    base_url = spec.base_url ? (location.href.match /^(http|https):\/\/[a-zA-Z0-9\-\.:]+/)
    if Object.prototype.toString.call(base_url) == '[object Array]'
        if base_url.length == 0
            base_url = location.href
        else
            base_url = base_url[0]

    if base_url[base_url.length-1] != '/'
        base_url += '/'
    spec.base_url = base_url

    _that = {}
    _.extend _that, helpers(spec)
    spec = _that.deep_copy spec

    # TODO: Make it switchable by spec
    connection_storage = stack()
    running_requests = 0
    max_requests = spec.max_requests ? 4

    spec.placeholder = spec.placeholder ? $('body')

    routes = (singleton ->
        _routes = []
        _that = {}

        _that.push = (elem) ->
            _routes.push elem

        _that.all = ->
            return _routes

        return _that
    )()

    wait_time = spec.wait_time ? 70

    pop_storage = ->
        if running_requests < max_requests
            req = connection_storage.pop()
            if req?
                req()

    request_finished = (fn) ->
        () ->
            running_requests -= 1
            
            pop_storage()
            fn.apply(null, arguments)

    wrap_request = (fn, data) ->
        () ->
            running_requests += 1
            data.error = request_finished data.error
            data.success = request_finished data.success

            fn data

    cached_memoize = (fn, data, new_tout, caching=true) ->
        key = _cache.genkey(data)
        cached = _cache.get(key)

        if cached? and caching and data.type == 'GET'
            if typeof cached.data == 'string'
                return data.success cached.data
            return data.success cached

        _cache.set(key, 'waiting', 15)
        return wrap_request(fn, data)()

    save_cache = (req_data, cache_key, fn) ->
                    (data, text_status, request) ->
                        if request? and request.getResponseHeader? and spec.expires == true
                            new_timeout = Date.parse(request.getResponseHeader('Expires'))

                        if not data.req_time?
                            if typeof data == 'string'
                                _cache.set(cache_key, { data: data }, req_data.planatir_timeout)
                            else
                                _cache.set(cache_key, data, req_data.palantir_timeout)

                        fn data
    
    on_error = (fn_succ, fn_err, cache_key) ->
                    (data) ->
                        cached = _cache.get(cache_key)

                        if cached?
                            if cached != 'waiting'
                                return fn_succ cached
                            _cache.delete(cache_key)

                        that.notifier.notify data

                        if fn_err?
                            fn_err data

    promise = (fn, args, key) ->
        () ->
            cached = _cache.get(key)

            if not cached? or cached != 'waiting'
                return fn.apply(args[1].success, args)
            if cached == 'waiting'
                setTimeout(promise(fn, args, key), wait_time)

    that.open = (req_data) ->
        if not req_data.type?
            req_data.type = 'GET'

        req_data.palantir_timeout = req_data.palantir_timeout ? 300

        key = _cache.genkey req_data
        args = [$.ajax, req_data, req_data.tout, req_data.caching]

        req_data.error = on_error(req_data.success, req_data.error, key)
        if req_data.type == 'GET' and req_data.palantir_cache != false

            req_data.success = save_cache(req_data, key, 
                req_data.success)
            if running_requests >= max_requests
                return connection_storage.push promise(cached_memoize, args, key)
            else
                return promise(cached_memoize, args, key)()

        else if running_requests >= max_requests    
            return connection_storage.push wrap_request $.ajax, req_data

        else if req_data.type != 'GET'
            _cache.delall req_data.url

        (wrap_request $.ajax, req_data)()


    that.template = (name, where) ->
        that.templates.open name, null, {where: where}
    
    that.route = (route, fn) ->
        routes.push({route: route, fn: fn})

        (_action=null) ->
            if _action == '_testing' then return fn
            fn.apply(null, arguments)

    that.route_for = (fn, params={}) ->
        #TODO: This is not a good way of figuring out a right function!
        fn = fn('_testing')
        matching = _.filter routes.all(), (item) ->
            if item.fn == fn then true else false

        prefix = if params.external then location.href.split('#')+'#' else ''

        if matching.length > 0
            return prefix + matching[0].route
        return undefined

    that.refresh = that.route '__refresh', (params) ->
        if not params?
            hashchange()

        [route, more_params] = that.helpers.\
            pull_params location.hash.slice(1)

        params = _.extend more_params, params

        if params.silent_refresh? and params.silent_refresh.toString() == 'true'
            delete params.silent_refresh
            params.silent = true
            return that.goto route, params

        delete params.silent
        route = '#' + that.helpers.add_params route, params
        window.location.hash = route

    that.goto = (route, params...) ->
        if params.length == 0
            params.push {}

        [route, more_params] = that.helpers.\
            pull_params route

        params[0] = _.extend more_params, params[0]    

        if (params.length > 0 and params[0].silent == true) or \
           route.slice(0,9) == that.route_for(that.refresh)
                res = _.where(routes.all(), {route: route})
                for matching in res
                    matching.fn params[0]
                return

        # The force is a special parameter that is always internal
        delete params.force
        route = '#'+that.helpers.add_params route, params
        window.location.hash = route

    inheriter = _.partial init, palantir, that, spec
    _cache = inheriter(cache)

    that.templates = inheriter template
    that.cache = inheriter cache
    that.notifier = inheriter notifier
    that.helpers = inheriter helpers
    that.gettext = inheriter gettext
    that.model = inheriter model
    that.validators = inheriter validators

    initiated_routes = (singleton ->
        _that = {}
        _routes = []

        $('body').on 'click', '[data-click]', that.templates.process_click

        _that.push = (route) ->
            _routes.push route

        _that.contains = (route) ->
            return _.contains _routes, route

        return _that
    )()
        
    hashchange = (e) ->
        e?.preventDefault?()
        e?.stopPropagation?()

        [route, params] = that.helpers.\
            pull_params location.hash.slice(1)
        res = _.where(routes.all(), {route: route})

        for matching in res
            if e == 'init'
                if not initiated_routes.contains(matching.route)
                    matching.fn(params)
                    initiated_routes.push matching.route
            else
                matching.fn(params)

    # Constructor
    setTimeout((() ->
        if spec.__inner == true
            return

        that.notifier.extend_code_messages spec.code_messages
        that.notifier.extend_messages spec.messages

        # We only want the last palantir instance to be in charge
        # of the hashchange event, as routes are pulled from a singleton
        # function
        $(window).off 'hashchange'
        $(window).on 'hashchange', (e) ->
            hashchange(e)

        hashchange('init')

        $('body').on 'click', 'a[data-route]', (e) ->
            e.preventDefault()
            that.goto($(e.target).attr('data-route'), {target: $(e.target).attr 'id'})
    ), 0)

    return that

# Exports to global scope
window.palantir = palantir
window.singleton = singleton
window.init = init
