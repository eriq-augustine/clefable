If you are interested in adding a new UI, then read this.

Just place your javascript file(s) in the ./referee/webui/js folder,
and your css in the ./referee/webui/style folder.

When this directory is loaded (resource_compiler.rb), the files in these
folders will automatically be loaded into the production js/css.

Finally, make sure to handle your game's hook properly in ./referee/webui/js/client_socket::loadGameState().
