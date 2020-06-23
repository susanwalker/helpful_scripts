require 'csv'
require 'byebug'

def parse_ar_csv(csv_path)
  contents = CSV.read(csv_path)
  parse_ar_contents(contents)
end

def parse_ar_contents(contents)
  current_company = nil
  current_patient = nil
  patients = []

  contents.each do |line|
    # if the line is a company
    if line[0]&.include?('Office : ')
      current_company = line[0].gsub('Office : ', '')
    # If first element in the line is an integer
    elsif line[0]&.to_i.to_s == line[0]
      # Get the patient (second element in the line)
      current_patient = {
        id: line[0].to_i,
        name: line[1]
      }
    elsif line[0] == 'Pat:'
      balance = line[-1].to_i

      # We ignore if the patient doesn't have any patient balance
      if balance == 0
        current_patient = nil
      else
        current_patient[:patient_balance] = balance
        current_patient[:company] = current_company
        patients << current_patient
        current_patient = nil
      end
    elsif current_patient
      current_patient[:phones] = line[0]
    end
  end

  patients
end

def parse_np_csvs(csv_paths)
  csv_paths.map(&method(:parse_np_csv)).flatten
end

def parse_np_csv(csv_path)
  contents = CSV.read(csv_path)
  parse_np_contents(contents)
end

def parse_np_contents(contents)
  patients = []

  contents.each do |line|
    # if the line starts with an integer
    if line[1]&.to_i.to_s == line[1]
      patient = {
        id: line[1].to_i,
        dob: line[3]
      }
      patients << patient
    end
  end

  patients
end

ar_patients = parse_ar_csv('xls/ar.csv')
np_patients = parse_np_csvs(['xls/np1.csv', 'xls/np2.csv', 'xls/np3.csv'])

final_patients =
  ar_patients.map do |ar_patient|
    np_patient = np_patients.find { |np| np[:id] == ar_patient[:id] }

    if np_patient
      ar_patient[:dob] = np_patient[:dob]
    else
      ar_patient[:dob] = 'Unknown'
    end

    ar_patient
  end

final_csv_path = 'final.csv'
CSV.open(final_csv_path, 'wb') do |csv|
  csv << ['id', 'name', 'dob', 'phones', 'patient_balance', 'company']
  final_patients.each do |patient|
    row = [
      patient[:id],
      patient[:name],
      patient[:dob],
      patient[:phones],
      patient[:patient_balance],
      patient[:company]
    ]

    csv << row
  end
end
