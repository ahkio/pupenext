$(document).on 'turbolinks:load', ->
  $('.pending_update').on 'cocoon:after-insert', (e, added_row) ->
    added_row.parent().parent().find(".submit").show()

    $('.key-select').on 'change', (e) ->
      $input    = $(e.target).next('input')
      $textarea = $(e.target).next('textarea')

      if $input && $(e.target).val() == 'lyhytkuvaus'
        $textarea = $(document.createElement('textarea'))

        $textarea.attr('name', $input.attr('name'))
                 .attr('id', $input.attr('id'))
                 .attr('cols', 40)
                 .attr('rows', 5)
                 .attr('style', "margin-bottom:-12px;")

        $input.replaceWith($textarea)
      else if $textarea
        $input = $(document.createElement('input'))

        $input.attr('name', $textarea.attr('name'))
              .attr('id', $textarea.attr('id'))
              .attr('class', 'medium')

        $textarea.replaceWith($input);

  $('.price-select').on 'change', ->
      this.form.submit()
