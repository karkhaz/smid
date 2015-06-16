MARKDOWN=$(wildcard web/*.md)
HTML=$(patsubst web/%.md,output/%.html,$(MARKDOWN))

default: $(HTML)

output/%.html: web/%.md web/syntaxizer.rb
	@mkdir -p $(dir $@)
	@cat $< | web/importer.rb | markdown > $@
