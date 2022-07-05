#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'aws-sdk-ec2'
  gem 'commander'
  gem 'nokogiri'
end

# AWS EBS Snapshot Deletion Utility
class EbsSnapshotUtil
  include Commander::Methods

  # Run command line utility
  def run
    program :name, 'ebs-snapshot-util'
    program :version, '0.0.1'
    program :description, 'AWS EBS Snapshot Utility'

    global_option '-p', '--profile PROFILE', 'AWS profile' do |profile|
      @profile = profile
    end

    global_option '-a', '--age DAYS', 'Snapshots older than AGE days' do |age|
      @age_in_days = age.to_i
    end

    command :list do |c|
      c.syntax = 'ebs-snapshot-util list <bucket>'
      c.summary = 'List EBS snapshots'
      c.description = 'List EBS snapshots'

      c.option(
        '-f',
        "--format #{format_options.join('|')}",
        String,
        "Output format (default: #{format_options.first})"
      )

      c.example(
        'List all EBS snapshots',
        'ebs-snapshot-util.rb list'
      )

      c.example(
        'List all EBS snapshots older than 90 days',
        'ebs-snapshot-util.rb list --age 90'
      )

      c.action do |_args, options|
        options.default(format: format_options.first)
        list(options.format)
      end
    end

    command :delete do |c|
      c.syntax = 'ebs-snapshot-util delete'
      c.summary = 'Delete EBS snapshots'
      c.description = 'Delete EBS snapshots. Requires --age option.'

      c.example(
        'Delete EBS snapshots older than 90 days',
        'ebs-snapshot-util.rb delete --age 90'
      )

      c.action do |_args, _options|
        delete
      end
    end

    run!
  end

  # AWS EC2 client
  def client
    @client ||= Aws::EC2::Client.new(profile: @profile)
  end

  # List EBS snapshots
  def list(format)
    unless format_options.include?(format)
      raise(
        ArgumentError,
        "Invalid format option, '#{format}'. Valid options: #{format_options.join(', ')}"
      )
    end

    puts format(snapshots, format) unless snapshots.empty?
  end

  # Delete EBS snapshots
  # Requires --age option
  def delete
    raise(ArgumentError, 'Required --age option missing') unless @age_in_days

    progress(snapshots) do |snapshot|
      begin
        @client.delete_snapshot(snapshot_id: snapshot.snapshot_id)
        # say_ok "=> Deleted #{snapshot.snapshot_id}"
      rescue Aws::EC2::Errors::InvalidSnapshotInUse => e
        say_warning "=> #{e.message}"
      end
    end
  end

  private

  # Valid format options
  def format_options
    %w[id json]
  end

  # Format snapshots
  def format(snapshots, format)
    send("to_#{format}".to_sym, snapshots)
  end

  def to_id(snapshots)
    snapshots.map(&:snapshot_id)
  end

  def to_json(snapshots)
    JSON.pretty_generate(snapshots.map(&:to_h))
  end

  # Snapshot matches filter criteria?
  def match?(snapshot)
    return true unless @age_in_days

    @age_in_days && age(snapshot) > @age_in_days * (60 * 60 * 24)
  end

  # Snapshot age in seconds
  def age(snapshot)
    Time.now.utc - snapshot.start_time
  end

  # Snapshots owned by the account and can be deleted, memoized
  def snapshots
    @snapshots ||= client.describe_snapshots(owner_ids: ['self']).map do |response|
      response.snapshots.select do |snapshot|
        deletable?(snapshot)
      end
    end.flatten
  end

  # Determine if snapshot can be deleted
  # - Not created by AWS Backup Service
  # - Matches filter criteria
  def deletable?(snapshot)
    !aws_backup?(snapshot) && match?(snapshot)
  end

  # Is the snapshot created by AWS Backup Service?
  def aws_backup?(snapshot)
    snapshot.tags.map { |t| t[:key] }.include?('aws:backup:source-resource')
  end
end

EbsSnapshotUtil.new.run if $PROGRAM_NAME == __FILE__
