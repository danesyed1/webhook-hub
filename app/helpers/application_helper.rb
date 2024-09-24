module ApplicationHelper
  def nav_link_class(path)
    base = "flex items-center gap-2 px-2 py-1.5 rounded text-sm transition-colors"
    if current_page?(path)
      "#{base} bg-gray-800 text-white"
    else
      "#{base} text-gray-400 hover:text-white hover:bg-gray-800"
    end
  end

  def sub_nav_link_class(path)
    base = "block px-2 py-1 text-xs rounded transition-colors"
    if request.path == path
      "#{base} text-white bg-gray-800"
    else
      "#{base} text-gray-500 hover:text-gray-300 hover:bg-gray-800/50"
    end
  end

  def status_badge(status)
    colors = {
      "delivered" => "bg-green-900/50 text-green-400 border-green-700",
      "pending"   => "bg-yellow-900/50 text-yellow-400 border-yellow-700",
      "processing" => "bg-blue-900/50 text-blue-400 border-blue-700",
      "failed"    => "bg-red-900/50 text-red-400 border-red-700",
      "queued"    => "bg-gray-800 text-gray-400 border-gray-700"
    }
    cls = colors[status] || "bg-gray-800 text-gray-400 border-gray-700"
    content_tag(:span, status, class: "inline-flex items-center px-2 py-0.5 rounded text-xs border #{cls}")
  end

  def http_status_badge(code)
    cls = if code&.between?(200, 299)
      "text-green-400"
    elsif code&.between?(400, 499)
      "text-yellow-400"
    else
      "text-red-400"
    end
    content_tag(:span, code || "—", class: "font-mono text-xs #{cls}")
  end
end
