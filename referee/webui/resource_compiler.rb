# Compile all the js files into a single one, and the same with the css files.

header = "/*\n * Do not modify.\n * This file was generated at #{Time.now()}.\n */\n"

# JS
`echo '#{header}' > ./referee/webui/compiled/scripts.js`
`cat ./referee/webui/js/*.js >> ./referee/webui/compiled/scripts.js`

# CSS
`echo '#{header}' > ./referee/webui/compiled/style.css`
`cat ./referee/webui/style/*.css >> ./referee/webui/compiled/style.css`
