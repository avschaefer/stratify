module ComponentHelper
  def ui_badge(text, type: :neutral)
    classes = case type.to_sym
              when :success
                'bg-emerald-50 text-emerald-700'
              when :warning
                'bg-amber-50 text-amber-700'
              when :danger, :error
                'bg-red-50 text-red-700'
              when :brand, :blue
                'bg-blue-50 text-blue-700'
              else
                'bg-gray-100 text-gray-600'
              end
              
    content_tag :span, text, class: "px-2.5 py-0.5 rounded-full text-xs font-medium #{classes}"
  end

  def ui_card(options = {}, &block)
    classes = "bg-white rounded-2xl border border-gray-200 shadow-sm #{options[:class]}"
    content_tag :div, class: classes, &block
  end
end

