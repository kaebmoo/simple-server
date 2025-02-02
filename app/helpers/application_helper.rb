module ApplicationHelper
  DEFAULT_PROGRAM_INCEPTION_DATE = Time.new(2018, 01, 01)
  STANDARD_DATE_DISPLAY_FORMAT = "%d-%^b-%Y"

  def bootstrap_class_for_flash(flash_type)
    case flash_type
      when 'success'
        'alert-success'
      when 'error'
        'alert-danger'
      when 'alert'
        'alert-warning'
      when 'notice'
        'alert-primary'
      else
        flash_type.to_s
    end
  end

  def display_date(date)
    date.strftime(STANDARD_DATE_DISPLAY_FORMAT)
  end

  def rounded_time_ago_in_words(date)
    if date == Date.current
      "Today"
    elsif date == Date.yesterday
      "Yesterday"
    else
      "on #{display_date(date)}".html_safe
    end
  end

  def handle_impossible_registration_date(date)
    program_inception_date =
      ENV['PROGRAM_INCEPTION_DATE'] ? ENV['PROGRAM_INCEPTION_DATE'].to_time : DEFAULT_PROGRAM_INCEPTION_DATE
    if date < program_inception_date # Date of inception of program
      'Unclear'
    else
      display_date(date)
    end
  end

  def show_last_interaction_date_and_result(patient)
    return if patient.appointments.count < 2

    last_interaction = patient.appointments.order(scheduled_date: :desc).second
    last_interaction_date = last_interaction.created_at.strftime(STANDARD_DATE_DISPLAY_FORMAT)
    interaction_result = "" + last_interaction_date

    if last_interaction.agreed_to_visit.present?
      interaction_result += ' - Agreed to visit'
    elsif last_interaction.remind_on.present?
      interaction_result += ' - Remind to call later'
    elsif last_interaction.status_visited?
      interaction_result += " - Visited facility"
    end

    interaction_result
  end
end

