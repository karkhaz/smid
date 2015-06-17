MARKDOWN=$(wildcard web/*.md)
HTML=$(patsubst web/%.md,output/%.html,$(MARKDOWN))

EXAMPLES=$(wildcard examples/*.sm)
IMAGES=$(patsubst examples/%.sm,examples/%.png,$(EXAMPLES))

default: $(HTML) $(IMAGES)

output/%.html: web/%.md web/syntaxizer.rb
	@mkdir -p $(dir $@)
	@cat $< | web/importer.rb | markdown > $@

examples/%.png: examples/%.dot
	@dot -Tpng $< > $@

examples/%.dot: examples/%.tmp.dot dot_formatter.rb
	@cat $< | ./dot_formatter.rb > $@

examples/%.tmp.dot: examples/%.sm
	@../smid -d $< > $@
