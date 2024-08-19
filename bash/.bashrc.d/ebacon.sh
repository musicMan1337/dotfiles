alias cdviper='cd /c/Viper'
alias cdsql='cd /c/TAG_SQL'
alias cdprojects='cd /c/tag-projects'
alias cdcore='cd /c/Core'

#~ React Stuff
REACT_ROOT='public/assets/App/viper/js/react'
VALID_VIPER_PATH='public\assets\App\viper\js\react\'

alias VSC='echo $VSC_CDIR'
alias cdDIR='cd $VSC_CDIR'

#~ eBacon quickly add a new component in ./components
#* ex: enc [CompName]
enc() {
  if [[ "$VSC_CDIR" != *"$VALID_VIPER_PATH"* ]]; then
    _dirError
  else
    cd $VSC_CDIR
    if [[ ! -d components ]]; then
      mkdir components
      touch components/index.js
    fi && mkdir components/"$1"
    cd components/"$1"
    touch "$1".js
    cd ..
    echo "export { default as $1 } from './$1/$1'" >>index.js
    cd ..
  fi
}

#* ebacon_init
ebacon_init() {
  if [[ "$VSC_CDIR" != *"$VALID_VIPER_PATH"* ]]; then
    _dirError
  else
    local FOLDER=$(basename $VSC_CDIR)
    echo
    echo "  ( •_•)>⌐■-■"
    echo
    cd $VSC_CDIR
    echo '⏳ Generating '$RED"$2"$RESET_ATTRS' boilerplate ⏳'

    echo 'Init '$PURPLE'".../'${FOLDER^}/'"'$RESET_ATTRS' and directories... '$GREEN'✔'$RESET_ATTRS
    mkdir components hooks state utils api
    touch index.tsx bb${FOLDER^}.tsx
    _writeToRootIndexTs
    _writeToBBMountTs

    echo 'Init '$PURPLE'"./components/index.ts"'$RESET_ATTRS'...... '$GREEN'✔'$RESET_ATTRS
    cd components
    touch index.ts
    echo '//~ export { default as CompName } from "./CompName/CompName";' >>index.ts
    cd ..

    echo 'Init '$PURPLE'"./state"'$RESET_ATTRS' files.............. '$GREEN'✔'$RESET_ATTRS
    cd state
    touch ${FOLDER^}Context.tsx initialState.ts
    _writeToContextTs
    _writeToInitialStateTs
    cd ..

    echo 'Init '$PURPLE'"./utils"'$RESET_ATTRS' files.............. '$GREEN'✔'$RESET_ATTRS
    cd utils
    touch constants.ts helpers.ts
    cd ..

    echo 'Init '$PURPLE'"./api"'$RESET_ATTRS' files................ '$GREEN'✔'$RESET_ATTRS
    cd api
    mkdir mutations queries
    touch endpoints.ts
    _writeToEndpointsTs

    cd mutations
    touch index.ts
    _writeToMutationsIndexTs
    cd ..

    cd queries
    touch index.ts
    _writeToQueriesIndexTs
    cd ..

    cd $VSC_CWD
    echo
    echo '⚡ (⌐■_■) ⚡'
    echo
  fi
}

#~ Helpers
_dirError() {
  echo $PURPLE'$VSC_CDIR '$RESET_ATTRS'variable is invalid!'
  echo $GREEN'Open the file location in a tab, then open a new terminal instance while on that file!'
  echo $RED'Current open file location '$RESET_ATTRS'-> '${VSC_CDIR}
}

_writeToEndpointsTs() {
  echo 'import axios from "axios";' >>endpoints.ts
  echo '' >>endpoints.ts
  echo 'const baseUrl = "/index.php/rest/...";' >>endpoints.ts
  echo '' >>endpoints.ts
  echo 'type Ctx = { signal?: AbortSignal };' >>endpoints.ts
  echo '' >>endpoints.ts
  echo 'export default {' >>endpoints.ts
  echo '  get: {' >>endpoints.ts
  echo '    example: async ({ signal }: Ctx, params: {}) => {' >>endpoints.ts
  echo '      const res = await axios.get<unknown[]>(`${baseUrl}/...`, {' >>endpoints.ts
  echo '        signal,' >>endpoints.ts
  echo '        params,' >>endpoints.ts
  echo '      });' >>endpoints.ts
  echo '      return res.data;' >>endpoints.ts
  echo '    },' >>endpoints.ts
  echo '  },' >>endpoints.ts
  echo '  post: {' >>endpoints.ts
  echo '    example: async (data: {}) => {' >>endpoints.ts
  echo '      const res = await axios.post<unknown[]>(`${baseUrl}/print`, data);' >>endpoints.ts
  echo '      return res.data;' >>endpoints.ts
  echo '    },' >>endpoints.ts
  echo '  },' >>endpoints.ts
  echo '  put: {},' >>endpoints.ts
  echo '  delete: {},' >>endpoints.ts
  echo '};' >>endpoints.ts
  echo '' >>endpoints.ts
}

_writeToMutationsIndexTs() {
  echo 'import { useMutation } from "@tanstack/react-query";' >>index.ts
  echo '' >>index.ts
  echo '# import { useSnackbar } from "eBacon/components"' >>index.ts
  echo '' >>index.ts
  echo '# import api from "../endpoints"' >>index.ts
  echo '' >>index.ts
  echo '# export function useExampleMutation() {' >>index.ts
  echo '#   const { addSnackbar } = useSnackbar()' >>index.ts
  echo '' >>index.ts
  echo ' #   return useMutation({' >>index.ts
  echo ' #     mutationFn: api.post.example,' >>index.ts
  echo ' #     onSuccess: (_data, _vars) => {' >>index.ts
  echo ' #       addSnackbar({' >>index.ts
  echo ' #         text: `Request successful`,' >>index.ts
  echo ' #         color: "success",' >>index.ts
  echo ' #         centered: true,' >>index.ts
  echo ' #       })' >>index.ts
  echo ' #     },' >>index.ts
  echo ' #     onError: (_data, _vars) => {' >>index.ts
  echo ' #       addSnackbar({' >>index.ts
  echo ' #         text: `Request failed, try again`,' >>index.ts
  echo ' #         color: "error",' >>index.ts
  echo ' #         centered: true,' >>index.ts
  echo ' #       })' >>index.ts
  echo ' #     },' >>index.ts
  echo ' #   })' >>index.ts
  echo ' # }' >>index.ts
  echo '' >>index.ts
}

_writeToQueriesIndexTs() {
  echo 'import { useQuery } from "@tanstack/react-query";' >>index.ts
  echo '' >>index.ts
  echo '# import { useSnackbar } from "eBacon/components"' >>index.ts
  echo '' >>index.ts
  echo '# import api from "../endpoints"' >>index.ts
  echo '' >>index.ts
  echo 'eport const exampleQueryKey = "domain-subdomain-example"' >>index.ts
  echo '' >>index.ts
  echo 'export function useExampleQuery(params: Parameters<typeof api.get.example>[1]) {' >>index.ts
  echo '  const { addSnackbar } = useSnackbar()' >>index.ts
  echo '' >>index.ts
  echo '  const query = useQuery({' >>index.ts
  echo '    queryKey: [exampleQueryKey, params],' >>index.ts
  echo '    queryFn: (ctx) => api.get.example(ctx, params),' >>index.ts
  echo '  })' >>index.ts
  echo '' >>index.ts
  echo '  useEffect(() => {' >>index.ts
  echo '    if (query.status === "error") {' >>index.ts
  echo '      addSnackbar({' >>index.ts
  echo '        text: "Error, refresh to try again",' >>index.ts
  echo '        color: "error",' >>index.ts
  echo '        centered: true,' >>index.ts
  echo '      })' >>index.ts
  echo '    }' >>index.ts
  echo '  }, [addSnackbar, query.status])' >>index.ts
  echo '' >>index.ts
  echo '  return query' >>index.ts
  echo '}' >>index.ts
  echo '' >>index.ts
}

_writeToInitialStateTs() {
  echo 'export type InitialState = {' >>initialState.ts
  echo '  _: string;' >>initialState.ts
  echo '};' >>initialState.ts
  echo '' >>initialState.ts
  echo 'export const initialState: InitialState = {' >>initialState.ts
  echo '  _: "",' >>initialState.ts
  echo '};' >>initialState.ts
  echo '' >>initialState.ts
}

_writeToContextTs() {
  echo 'import React, { createContext, useContext } from "react";' >>${FOLDER^}Context.ts
  echo '' >>${FOLDER^}Context.ts
  echo 'import { initialState, type InitialState } from "./initialState";' >>${FOLDER^}Context.ts
  echo '' >>${FOLDER^}Context.ts
  echo 'const ExampleContext = createContext(initialState);' >>${FOLDER^}Context.ts
  echo '' >>${FOLDER^}Context.ts
  echo 'export const ExampleProvider = (props: { children: React.ReactNode }) => {' >>${FOLDER^}Context.ts
  echo '  const value: InitialState = {' >>${FOLDER^}Context.ts
  echo '    _: "",' >>${FOLDER^}Context.ts
  echo '  };' >>${FOLDER^}Context.ts
  echo '' >>${FOLDER^}Context.ts
  echo '  return (' >>${FOLDER^}Context.ts
  echo '    <ExampleContext.Provider value={value}>' >>${FOLDER^}Context.ts
  echo '      {props.children}' >>${FOLDER^}Context.ts
  echo '    </ExampleContext.Provider>' >>${FOLDER^}Context.ts
  echo '  );' >>${FOLDER^}Context.ts
  echo '};' >>${FOLDER^}Context.ts
  echo '' >>${FOLDER^}Context.ts
  echo 'export const useExampleContext = () => {' >>${FOLDER^}Context.ts
  echo '  return useContext(ExampleContext);' >>${FOLDER^}Context.ts
  echo '};' >>${FOLDER^}Context.ts
  echo '' >>${FOLDER^}Context.ts
}

_writeToRootIndexTs() {
  echo 'import React from "react";' >>index.tsx
  echo '' >>index.tsx
  echo 'export default function '${FOLDER^}'App() {' echo >>index.tsx
  echo '  return (' >>index.tsx
  echo '    <>' >>index.tsx
  echo '      <div>Hello World</div>' >>index.tsx
  echo '    </>' >>index.tsx
  echo '  );' >>index.tsx
  echo '}' >>index.tsx
  echo '' >>index.tsx
}

_writeToBBMountTs() {
  echo 'import React from "react";' >>bb${FOLDER^}.tsx
  echo '' >>bb${FOLDER^}.tsx
  echo 'import { viperRender } from "viper-react-helper";' >>bb${FOLDER^}.tsx
  echo 'import ReactRouterProviders from "eBacon/backbone/ReactRouterProviders";' >>bb${FOLDER^}.tsx
  echo '' >>bb${FOLDER^}.tsx
  echo 'import Example from ".";' >>bb${FOLDER^}.tsx
  echo '' >>bb${FOLDER^}.tsx
  echo 'const startExampleApp = () => {' >>bb${FOLDER^}.tsx
  echo '  viperRender(' >>bb${FOLDER^}.tsx
  echo '    <ReactRouterProviders path="system/example">' >>bb${FOLDER^}.tsx
  echo '      <Example />' >>bb${FOLDER^}.tsx
  echo '    </ReactRouterProviders>,' >>bb${FOLDER^}.tsx
  echo '    document.getElementById("viperTwoPanel__rightContent"),' >>bb${FOLDER^}.tsx
  echo '  );' >>bb${FOLDER^}.tsx
  echo '};' >>bb${FOLDER^}.tsx
  echo '' >>bb${FOLDER^}.tsx
  echo 'Viper.ReactAppLoader.example = {' >>bb${FOLDER^}.tsx
  echo '  init: function () {' >>bb${FOLDER^}.tsx
  echo '    startExampleApp();' >>bb${FOLDER^}.tsx
  echo '  },' >>bb${FOLDER^}.tsx
  echo '};' >>bb${FOLDER^}.tsx
  echo '' >>bb${FOLDER^}.tsx
}
