
" ensure latest context
func! ncm2#on_complete#context_ensure(fn, ...) dict
    let ctx = a:000[-1]
    if ncm2#context_dated(ctx)
        call ncm2#complete(ctx, ctx.startccol, [], 1)
        return
    endif
    call call(a:fn, a:000, self)
endfunc

" add delay to on_complete
func! ncm2#on_complete#delay(delay, ...) dict
    let sr = self
    if has_key(self, '_ncm2_on_complete_timer')
        call timer_stop(sr._ncm2_on_complete_timer)
        unlet sr._ncm2_on_complete_timer
    endif
    let args = a:000
    let sr._ncm2_on_complete_timer = timer_start(
                \ a:delay,
                \ {_-> s:delay_handler(sr, args)})
endfunc

func! s:delay_handler(sr, args)
    unlet a:sr._ncm2_on_complete_timer
    call call('ncm2#on_complete#context_ensure', a:args, a:sr)
endfunc

" omnifunc wrapper
func! ncm2#on_complete#omni(funcname, ctx)
    " omni function's startbcol is zero based, convert it to one based
    let startbcol = call(a:funcname, [1,'']) + 1
    let typed = strpart(getline('.'), 0, col('.')-1)
    let base = typed[startbcol - 1: ]
    let matches = call(a:funcname, [0, base])
    let refresh = 0
    if type(matches) == v:t_dict
        let refresh = get(matches, 'refresh', '') == 'always' ? 1: 0
        let matches = matches.words
    endif

    " convert startbcol -> startccol
    if startbcol == 1
        let startccol = 1
    else
        let tmp = typed[: startbcol - 2]
        let startccol = strchars(tmp) + 1
    endif

    " omnifunc doesn't know anything about subscope
    " hack scope_ccol sot that it won't be adjusted by ncm2_core
    let a:ctx.scope_ccol = 1

    call ncm2#complete(a:ctx, startccol, matches, refresh)
endfunc

