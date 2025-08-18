module ApplicationHelper
  def format_currency(amount)
    number_with_delimiter(amount)
  end
  
  def format_currency_with_symbol(amount)
    "JPY #{format_currency(amount)}"
  end
end
