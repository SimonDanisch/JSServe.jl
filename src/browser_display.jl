struct BrowserDisplay <: Base.Multimedia.AbstractDisplay end

function openurl(url::String)
    if Sys.isapple()
        success(`open $url`) && return
    elseif Sys.iswindows()
        success(`powershell.exe start $url`) && return
    elseif Sys.isunix()
        success(`xdg-open $url`) && return
        success(`gnome-open $url`) && return
    end
    success(`python -mwebbrowser $(url)`) && return
    # our last hope
    success(`python3 -mwebbrowser $(url)`) && return
    @warn("Can't find a way to open a browser, open $(url) manually!")
end

function Base.display(::BrowserDisplay, dom::DisplayInline)
    application = get_global_app()
    session = Session()
    session_url = "/browser-display"
    route_was_present = route!(application, session_url) do context
        # Serve the actual content
        application = context.application
        application.sessions[session.id] = session
        html_dom = Base.invokelatest(dom.dom_function, session, context.request)
        return html(dom2html(session, html_dom))
    end
    # Only open url first time!
    if isempty(application.sessions)
        openurl(local_url(application, session_url))
    else
        for (id, session) in application.sessions
            evaljs(session, js"location.reload(true)")
        end
    end
    return session
end