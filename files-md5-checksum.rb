#!/usr/bin/ruby
# frozen_string_literal: true

require 'digest/sha2'

begin
  # Read user input
  puts 'Enter directory path:'
  directory_path = gets.chomp

  # Read user input
  puts 'Enter file mask: '
  file_mask = gets.chomp

  # Change directory to given path
  Dir.chdir(directory_path.to_s)

  # Find files with given mask
  all_files = Dir.glob("./**/#{file_mask}")

  # End if no files found
  if all_files.length.zero?
    puts 'No files found'
    exit 1
  end

  # key => calculated checksum, value => array of files
  checksum_files_hash = {}

  # Calculate checksum for each file and store in hash
  all_files.each do |file|
    checksum = Digest::MD5.hexdigest(File.read(file))
    checksum_files = checksum_files_hash[checksum]
    if checksum_files.nil?
      checksum_files = [file]
      checksum_files_hash.store(checksum, checksum_files)
    else
      checksum_files.append(file)
    end
  end

rescue Errno::ENOENT
  puts 'Directory not found'

rescue Errno::EINVAL
  puts 'Ivalid path pattern'

else
  # filter out non-duplicated checksums
  duplicated_checksum_files_hash = (checksum_files_hash.select { |__checksum, files| files.length > 1 })

  puts 'No duplicates found' if duplicated_checksum_files_hash.length.zero?

  # Iterate over hash and compare bytes for each checksum group
  duplicated_checksum_files_hash.each do |checksum, files|
    duplicated_bytes_files = []

    # Compare each file one-by-one with other files and find duplicated bytes
    files.each do |file|
      file_bytes = File.read(file).bytes

      other_files = files.clone
      other_files.delete(file)

      other_files.each do |other_file|
        other_file_bytes = File.read(other_file).bytes
        duplicated_bytes_files.append(file) if file_bytes == other_file_bytes && !duplicated_bytes_files.include?(file)
      end
    end

    # Print output
    puts '', "Checksum: #{checksum}"
    if duplicated_bytes_files.length.zero?
      puts 'No duplicates found'
    else
      puts "Files: #{duplicated_bytes_files}"
    end
  end
end
