## app/inputs/date_time_picker_input.rb
class DateTimePickerInput < SimpleForm::Inputs::Base
  def input
    @builder.text_field(attribute_name, input_html_options)
  end

  def input_html_options
    super.merge({class: 'form-control form_datetime', readonly: true})
  end

  def span_remove
    template.content_tag(:span, class: 'input-group-addon') do
      template.concat icon_remove
    end
  end

  def span_table
    template.content_tag(:span, class: 'input-group-addon') do
      template.concat icon_table
    end
  end

  def icon_remove
    "<i class='glyphicon glyphicon-remove'></i>".html_safe
  end

  def icon_table
    "<i class='glyphicon glyphicon-th'></i>".html_safe
  end

end