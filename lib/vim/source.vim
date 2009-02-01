            function! GetOpenBufferPaths()                                                  
                let tablist = []
                let pathlist = []
                let cwd = getcwd()
                for i in range(tabpagenr('$'))
                    call extend(tablist, tabpagebuflist(i + 1))
                endfor
                for i in tablist
                    let bufn = bufname(i)
                    if (bufn =~ '^/')==0
                      call add(pathlist, cwd . '/' . bufn)
                    else
                      call add(pathlist, bufn)
                    end
                endfor
                call filter(pathlist, "v:val != cwd.'/'" )
                return pathlist
            endfunction
