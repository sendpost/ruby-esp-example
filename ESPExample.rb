#!/usr/bin/env ruby
# frozen_string_literal: true

=begin
Comprehensive SendPost Ruby SDK Example for Email Service Providers (ESPs)

This example demonstrates a complete workflow that an ESP would typically follow:
1. Create sub-accounts for different clients or use cases
2. Set up webhooks to receive email event notifications
3. Add and verify sending domains
4. Send transactional and marketing emails
5. Retrieve message details for tracking and debugging
6. Monitor statistics via IPs and IP pools
7. Manage IP pools for better deliverability control

To run this example:
1. Set environment variables:
   - SENDPOST_SUB_ACCOUNT_API_KEY: Your sub-account API key
   - SENDPOST_ACCOUNT_API_KEY: Your account API key
2. Or modify the API_KEY constants below
3. Update email addresses and domain names with your verified values
4. Run: ruby ESPExample.rb
=end

require 'date'
require 'time'
require 'sendpost_ruby_sdk'

# Add the parent directory to the path to import the SDK if needed
# $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'sendpost-ruby-sdk', 'lib'))

class ESPExample
  # API Configuration
  BASE_PATH = 'https://api.sendpost.io/api/v1'
  
  # API Keys - Set these or use environment variables
  SUB_ACCOUNT_API_KEY = ENV['SENDPOST_SUB_ACCOUNT_API_KEY'] || 'YOUR_SUB_ACCOUNT_API_KEY_HERE'
  ACCOUNT_API_KEY = ENV['SENDPOST_ACCOUNT_API_KEY'] || 'YOUR_ACCOUNT_API_KEY_HERE'
  
  # Configuration - Update these with your values
  TEST_FROM_EMAIL = 'sender@yourdomain.com'
  TEST_TO_EMAIL = 'recipient@example.com'
  TEST_DOMAIN_NAME = 'yourdomain.com'
  WEBHOOK_URL = 'https://your-webhook-endpoint.com/webhook'
  
  def initialize
    @created_sub_account_id = nil
    @created_sub_account_api_key = nil
    @created_webhook_id = nil
    @created_domain_id = nil
    @created_ip_pool_id = nil
    @created_ip_pool_name = nil
    @sent_message_id = nil
  end
  
  def get_sub_account_config
    config = Sendpost::Configuration.new
    config.host = BASE_PATH
    config.api_key['X-SubAccount-ApiKey'] = SUB_ACCOUNT_API_KEY
    config
  end
  
  def get_account_config
    config = Sendpost::Configuration.new
    config.host = BASE_PATH
    config.api_key['X-Account-ApiKey'] = ACCOUNT_API_KEY
    config
  end
  
  def list_sub_accounts
    puts "\n=== Step 1: Listing All Sub-Accounts ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      sub_account_api = Sendpost::SubAccountApi.new(api_client)
      
      puts 'Retrieving all sub-accounts...'
      sub_accounts = sub_account_api.get_all_sub_accounts
      
      puts "✓ Retrieved #{sub_accounts.length} sub-account(s)"
      sub_accounts.each do |sub_account|
        puts "  - ID: #{sub_account.id}"
        puts "    Name: #{sub_account.name}"
        puts "    API Key: #{sub_account.api_key}"
        account_type = (sub_account.type == 1) ? 'Plus' : 'Regular'
        puts "    Type: #{account_type}"
        blocked = sub_account.blocked ? 'Yes' : 'No'
        puts "    Blocked: #{blocked}"
        puts "    Created: #{sub_account.created}" if sub_account.created
        puts
        
        # Use first sub-account if none selected
        if @created_sub_account_id.nil? && sub_account.id
          @created_sub_account_id = sub_account.id
          @created_sub_account_api_key = sub_account.api_key
        end
      end
    rescue Sendpost::ApiError => e
      puts "✗ Failed to list sub-accounts:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def create_sub_account
    puts "\n=== Step 2: Creating Sub-Account ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      sub_account_api = Sendpost::SubAccountApi.new(api_client)
      
      # Create new sub-account request
      new_sub_account = Sendpost::CreateSubAccountRequest.new
      new_sub_account.name = "ESP Client - #{Time.now.to_i}"
      
      puts "Creating sub-account: #{new_sub_account.name}"
      
      sub_account = sub_account_api.create_sub_account(new_sub_account)
      
      @created_sub_account_id = sub_account.id
      @created_sub_account_api_key = sub_account.api_key
      
      puts '✓ Sub-account created successfully!'
      puts "  ID: #{@created_sub_account_id}"
      puts "  Name: #{sub_account.name}"
      puts "  API Key: #{@created_sub_account_api_key}"
      account_type = (sub_account.type == 1) ? 'Plus' : 'Regular'
      puts "  Type: #{account_type}"
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to create sub-account:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def create_webhook
    puts "\n=== Step 3: Creating Webhook ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      webhook_api = Sendpost::WebhookApi.new(api_client)
      
      # Create new webhook
      new_webhook = Sendpost::CreateWebhookRequest.new
      new_webhook.url = WEBHOOK_URL
      new_webhook.enabled = true
      
      # Configure which events to receive
      new_webhook.processed = true      # Email processed
      new_webhook.delivered = true      # Email delivered
      new_webhook.dropped = true        # Email dropped
      new_webhook.soft_bounced = true   # Soft bounce
      new_webhook.hard_bounced = true   # Hard bounce
      new_webhook.opened = true         # Email opened
      new_webhook.clicked = true        # Link clicked
      new_webhook.unsubscribed = true   # Unsubscribed
      new_webhook.spam = true           # Marked as spam
      
      puts 'Creating webhook...'
      puts "  URL: #{new_webhook.url}"
      
      webhook = webhook_api.create_webhook(new_webhook)
      @created_webhook_id = webhook.id
      
      puts '✓ Webhook created successfully!'
      puts "  ID: #{@created_webhook_id}"
      puts "  URL: #{webhook.url}"
      puts "  Enabled: #{webhook.enabled}"
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to create webhook:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def list_webhooks
    puts "\n=== Step 4: Listing All Webhooks ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      webhook_api = Sendpost::WebhookApi.new(api_client)
      
      puts 'Retrieving all webhooks...'
      webhooks = webhook_api.get_all_webhooks
      
      puts "✓ Retrieved #{webhooks.length} webhook(s)"
      webhooks.each do |webhook|
        puts "  - ID: #{webhook.id}"
        puts "    URL: #{webhook.url}"
        puts "    Enabled: #{webhook.enabled}"
        puts
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to list webhooks:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def add_domain
    puts "\n=== Step 5: Adding Domain ==="
    
    begin
      config = get_sub_account_config
      api_client = Sendpost::ApiClient.new(config)
      domain_api = Sendpost::DomainApi.new(api_client)
      
      # Create domain request
      domain_request = Sendpost::CreateDomainRequest.new
      domain_request.name = TEST_DOMAIN_NAME
      
      puts "Adding domain: #{TEST_DOMAIN_NAME}"
      
      domain = domain_api.subaccount_domain_post(domain_request)
      @created_domain_id = domain.id.to_s if domain.id
      
      puts '✓ Domain added successfully!'
      puts "  ID: #{@created_domain_id}"
      puts "  Domain: #{domain.name}"
      verified = domain.verified ? 'Yes' : 'No'
      puts "  Verified: #{verified}"
      
      if domain.dkim
        puts "  DKIM Record: #{domain.dkim.text_value}"
      end
      
      puts "\n⚠️  IMPORTANT: Add the DNS records shown above to your domain's DNS settings to verify the domain."
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to add domain:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def list_domains
    puts "\n=== Step 6: Listing All Domains ==="
    
    begin
      config = get_sub_account_config
      api_client = Sendpost::ApiClient.new(config)
      domain_api = Sendpost::DomainApi.new(api_client)
      
      puts 'Retrieving all domains...'
      domains = domain_api.get_all_domains
      
      puts "✓ Retrieved #{domains.length} domain(s)"
      domains.each do |domain|
        puts "  - ID: #{domain.id}"
        puts "    Domain: #{domain.name}"
        verified = domain.verified ? 'Yes' : 'No'
        puts "    Verified: #{verified}"
        puts
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to list domains:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def send_transactional_email
    puts "\n=== Step 7: Sending Transactional Email ==="
    
    begin
      config = get_sub_account_config
      api_client = Sendpost::ApiClient.new(config)
      email_api = Sendpost::EmailApi.new(api_client)
      
      # Create email message
      email_message = Sendpost::EmailMessageObject.new
      
      # Set sender
      from_addr = Sendpost::EmailMessageFrom.new
      from_addr.email = TEST_FROM_EMAIL
      from_addr.name = 'Your Company'
      email_message.from = from_addr
      
      # Set recipient
      recipient = Sendpost::EmailMessageToInner.new
      recipient.email = TEST_TO_EMAIL
      recipient.name = 'Customer'
      
      # Add custom fields
      recipient.custom_fields = {
        'customer_id' => '67890',
        'order_value' => '99.99'
      }
      
      email_message.to = [recipient]
      
      # Set email content
      email_message.subject = 'Order Confirmation - Transactional Email'
      email_message.html_body = '<h1>Thank you for your order!</h1><p>Your order has been confirmed and will be processed shortly.</p>'
      email_message.text_body = 'Thank you for your order! Your order has been confirmed and will be processed shortly.'
      
      # Enable tracking
      email_message.track_opens = true
      email_message.track_clicks = true
      
      # Add custom headers for tracking
      email_message.headers = {
        'X-Order-ID' => '12345',
        'X-Email-Type' => 'transactional'
      }
      
      # Use IP pool if available
      if @created_ip_pool_name
        email_message.ippool = @created_ip_pool_name
        puts "  Using IP Pool: #{@created_ip_pool_name}"
      end
      
      puts 'Sending transactional email...'
      puts "  From: #{TEST_FROM_EMAIL}"
      puts "  To: #{TEST_TO_EMAIL}"
      puts "  Subject: #{email_message.subject}"
      
      responses = email_api.send_email(email_message)
      
      if responses && !responses.empty?
        response = responses[0]
        @sent_message_id = response.message_id
        
        puts '✓ Transactional email sent successfully!'
        puts "  Message ID: #{@sent_message_id}"
        puts "  To: #{response.to}"
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to send email:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def send_marketing_email
    puts "\n=== Step 8: Sending Marketing Email ==="
    
    begin
      config = get_sub_account_config
      api_client = Sendpost::ApiClient.new(config)
      email_api = Sendpost::EmailApi.new(api_client)
      
      # Create email message
      email_message = Sendpost::EmailMessageObject.new
      
      # Set sender
      from_addr = Sendpost::EmailMessageFrom.new
      from_addr.email = TEST_FROM_EMAIL
      from_addr.name = 'Marketing Team'
      email_message.from = from_addr
      
      # Set recipient
      recipient = Sendpost::EmailMessageToInner.new
      recipient.email = TEST_TO_EMAIL
      recipient.name = 'Customer 1'
      
      email_message.to = [recipient]
      
      # Set email content
      email_message.subject = 'Special Offer - 20% Off Everything!'
      email_message.html_body = '<html><body><h1>Special Offer!</h1><p>Get 20% off on all products. Use code: <strong>SAVE20</strong></p><p><a href="https://example.com/shop">Shop Now</a></p></body></html>'
      email_message.text_body = 'Special Offer! Get 20% off on all products. Use code: SAVE20. Visit: https://example.com/shop'
      
      # Enable tracking
      email_message.track_opens = true
      email_message.track_clicks = true
      
      # Add group for analytics
      email_message.groups = ['marketing', 'promotional']
      
      # Add custom headers
      email_message.headers = {
        'X-Email-Type' => 'marketing',
        'X-Campaign-ID' => 'campaign-001'
      }
      
      # Use IP pool if available
      if @created_ip_pool_name
        email_message.ippool = @created_ip_pool_name
        puts "  Using IP Pool: #{@created_ip_pool_name}"
      end
      
      puts 'Sending marketing email...'
      puts "  From: #{TEST_FROM_EMAIL}"
      puts "  To: #{TEST_TO_EMAIL}"
      puts "  Subject: #{email_message.subject}"
      
      responses = email_api.send_email(email_message)
      
      if responses && !responses.empty?
        response = responses[0]
        @sent_message_id = response.message_id if @sent_message_id.nil?
        
        puts '✓ Marketing email sent successfully!'
        puts "  Message ID: #{response.message_id}"
        puts "  To: #{response.to}"
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to send email:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def get_message_details
    puts "\n=== Step 9: Retrieving Message Details ==="
    
    if @sent_message_id.nil?
      puts '✗ No message ID available. Please send an email first.'
      return
    end
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      message_api = Sendpost::MessageApi.new(api_client)
      
      puts "Retrieving message with ID: #{@sent_message_id}"
      
      message = message_api.get_message_by_id(@sent_message_id)
      
      puts '✓ Message retrieved successfully!'
      puts "  Message ID: #{message.message_id}"
      puts "  Account ID: #{message.account_id}"
      puts "  Sub-Account ID: #{message.sub_account_id}"
      puts "  IP ID: #{message.ip_id}"
      puts "  Public IP: #{message.public_ip}"
      puts "  Local IP: #{message.local_ip}"
      puts "  Email Type: #{message.email_type}"
      
      puts "  Submitted At: #{message.submitted_at}" if message.submitted_at
      
      if message.from
        from_email = message.from.is_a?(Hash) ? message.from['email'] : (message.from.respond_to?(:email) ? message.from.email : 'N/A')
        puts "  From: #{from_email}"
      end
      
      if message.to
        to_email = message.to.respond_to?(:email) ? message.to.email : 'N/A'
        puts "  To: #{to_email}"
        puts "    Name: #{message.to.name}" if message.to.respond_to?(:name) && message.to.name
      end
      
      puts "  Subject: #{message.subject}" if message.subject
      puts "  IP Pool: #{message.ip_pool}" if message.ip_pool
      puts "  Delivery Attempts: #{message.attempt}" if message.attempt
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to get message:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def get_sub_account_stats
    puts "\n=== Step 10: Getting Sub-Account Statistics ==="
    
    if @created_sub_account_id.nil?
      puts '✗ No sub-account ID available. Please create or list sub-accounts first.'
      return
    end
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      stats_api = Sendpost::StatsApi.new(api_client)
      
      # Get stats for the last 7 days
      to_date = Date.today
      from_date = to_date - 7
      
      puts "Retrieving stats for sub-account ID: #{@created_sub_account_id}"
      puts "  From: #{from_date}"
      puts "  To: #{to_date}"
      
      stats = stats_api.account_subaccount_stat_subaccount_id_get(from_date, to_date, @created_sub_account_id)
      
      puts '✓ Stats retrieved successfully!'
      puts "  Retrieved #{stats.length} stat record(s)"
      
      total_processed = 0
      total_delivered = 0
      
      stats.each do |stat|
        puts "\n  Date: #{stat.date}"
        if stat.stat
          stat_data = stat.stat
          puts "    Processed: #{stat_data.processed || 0}"
          puts "    Delivered: #{stat_data.delivered || 0}"
          puts "    Dropped: #{stat_data.dropped || 0}"
          puts "    Hard Bounced: #{stat_data.hard_bounced || 0}"
          puts "    Soft Bounced: #{stat_data.soft_bounced || 0}"
          puts "    Unsubscribed: #{stat_data.unsubscribed || 0}"
          puts "    Spam: #{stat_data.spam || 0}"
          
          total_processed += stat_data.processed || 0
          total_delivered += stat_data.delivered || 0
        end
      end
      
      puts "\n  Summary (Last 7 days):"
      puts "    Total Processed: #{total_processed}"
      puts "    Total Delivered: #{total_delivered}"
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to get stats:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def get_aggregate_stats
    puts "\n=== Step 11: Getting Aggregate Statistics ==="
    
    if @created_sub_account_id.nil?
      puts '✗ No sub-account ID available. Please create or list sub-accounts first.'
      return
    end
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      stats_api = Sendpost::StatsApi.new(api_client)
      
      # Get aggregate stats for the last 7 days
      to_date = Date.today
      from_date = to_date - 7
      
      puts "Retrieving aggregate stats for sub-account ID: #{@created_sub_account_id}"
      puts "  From: #{from_date}"
      puts "  To: #{to_date}"
      
      aggregate_stat = stats_api.account_subaccount_stat_subaccount_id_aggregate_get(from_date, to_date, @created_sub_account_id)
      
      puts '✓ Aggregate stats retrieved successfully!'
      puts "  Processed: #{aggregate_stat.processed || 0}"
      puts "  Delivered: #{aggregate_stat.delivered || 0}"
      puts "  Dropped: #{aggregate_stat.dropped || 0}"
      puts "  Hard Bounced: #{aggregate_stat.hard_bounced || 0}"
      puts "  Soft Bounced: #{aggregate_stat.soft_bounced || 0}"
      puts "  Unsubscribed: #{aggregate_stat.unsubscribed || 0}"
      puts "  Spam: #{aggregate_stat.spam || 0}"
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to get aggregate stats:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def list_ips
    puts "\n=== Step 12: Listing All IPs ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      ip_api = Sendpost::IPApi.new(api_client)
      
      puts 'Retrieving all IPs...'
      ips = ip_api.get_all_ips
      
      puts "✓ Retrieved #{ips.length} IP(s)"
      ips.each do |ip|
        puts "  - ID: #{ip.id}"
        puts "    IP Address: #{ip.public_ip}"
        puts "    Reverse DNS: #{ip.reverse_dns_hostname}" if ip.reverse_dns_hostname
        puts "    Created: #{ip.created}" if ip.created
        puts
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to list IPs:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def create_ip_pool
    puts "\n=== Step 13: Creating IP Pool ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      ip_pools_api = Sendpost::IPPoolsApi.new(api_client)
      
      # First, get available IPs
      ip_api = Sendpost::IPApi.new(api_client)
      ips = ip_api.get_all_ips
      
      if ips.empty?
        puts '⚠️  No IPs available. Please allocate IPs first.'
        return
      end
      
      # Create IP pool request
      pool_request = Sendpost::IPPoolCreateRequest.new
      pool_request.name = "Marketing Pool #{Time.now.to_i}"
      pool_request.routing_strategy = 0  # 0 = RoundRobin, 1 = EmailProviderStrategy
      
      # Add IPs to the pool (convert IP to EIP)
      pool_ips = []
      # Add first available IP (you can add more)
      if !ips.empty?
        eip = Sendpost::EIP.new
        eip.public_ip = ips[0].public_ip
        pool_ips << eip
      end
      pool_request.ips = pool_ips
      
      # Set warmup interval (required, must be > 0)
      pool_request.warmup_interval = 24  # 24 hours
      
      # Set overflow strategy (0 = None, 1 = Use overflow pool)
      pool_request.overflow_strategy = 0
      
      puts "Creating IP pool: #{pool_request.name}"
      puts '  Routing Strategy: Round Robin'
      puts "  IPs: #{pool_ips.length}"
      puts "  Warmup Interval: #{pool_request.warmup_interval} hours"
      
      ip_pool = ip_pools_api.create_ip_pool(pool_request)
      @created_ip_pool_id = ip_pool.id
      @created_ip_pool_name = ip_pool.name if ip_pool.name
      
      puts '✓ IP pool created successfully!'
      puts "  ID: #{@created_ip_pool_id}"
      puts "  Name: #{ip_pool.name}"
      puts "  Routing Strategy: #{ip_pool.routing_strategy}"
      puts "  IPs in pool: #{ip_pool.ips ? ip_pool.ips.length : 0}"
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to create IP pool:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def list_ip_pools
    puts "\n=== Step 14: Listing All IP Pools ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      ip_pools_api = Sendpost::IPPoolsApi.new(api_client)
      
      puts 'Retrieving all IP pools...'
      ip_pools = ip_pools_api.get_all_ip_pools
      
      puts "✓ Retrieved #{ip_pools.length} IP pool(s)"
      ip_pools.each do |ip_pool|
        puts "  - ID: #{ip_pool.id}"
        puts "    Name: #{ip_pool.name}"
        puts "    Routing Strategy: #{ip_pool.routing_strategy}"
        puts "    IPs in pool: #{ip_pool.ips ? ip_pool.ips.length : 0}"
        if ip_pool.ips
          ip_pool.ips.each do |ip|
            puts "      - #{ip.public_ip}"
          end
        end
        puts
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to list IP pools:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def get_account_stats
    puts "\n=== Step 15: Getting Account-Level Statistics ==="
    
    begin
      config = get_account_config
      api_client = Sendpost::ApiClient.new(config)
      stats_a_api = Sendpost::StatsAApi.new(api_client)
      
      # Get stats for the last 7 days
      to_date = Date.today
      from_date = to_date - 7
      
      puts 'Retrieving account-level stats...'
      puts "  From: #{from_date}"
      puts "  To: #{to_date}"
      
      account_stats = stats_a_api.get_all_account_stats(from_date, to_date)
      
      puts '✓ Account stats retrieved successfully!'
      puts "  Retrieved #{account_stats.length} stat record(s)"
      
      account_stats.each do |stat|
        puts "\n  Date: #{stat.date}"
        if stat.stat
          stat_data = stat.stat
          puts "    Processed: #{stat_data.processed || 0}"
          puts "    Delivered: #{stat_data.delivered || 0}"
          puts "    Dropped: #{stat_data.dropped || 0}"
          puts "    Hard Bounced: #{stat_data.hard_bounced || 0}"
          puts "    Soft Bounced: #{stat_data.soft_bounced || 0}"
          puts "    Opens: #{stat_data.opened || 0}"
          puts "    Clicks: #{stat_data.clicked || 0}"
          puts "    Unsubscribed: #{stat_data.unsubscribed || 0}"
          puts "    Spam: #{stat_data.spam || 0}"
        end
      end
      
    rescue Sendpost::ApiError => e
      puts "✗ Failed to get account stats:"
      puts "  Status code: #{e.code}"
      puts "  Response body: #{e.response_body}"
      puts e.backtrace
    rescue StandardError => e
      puts "✗ Unexpected error:"
      puts e.message
      puts e.backtrace
    end
  end
  
  def run_complete_workflow
    puts '╔═══════════════════════════════════════════════════════════════╗'
    puts '║   SendPost Ruby SDK - ESP Example Workflow                    ║'
    puts '╚═══════════════════════════════════════════════════════════════╝'
    
    # Step 1: List existing sub-accounts (or create new one)
    list_sub_accounts
    
    # Step 2: Create webhook for event notifications
    # create_webhook()
    list_webhooks
    
    # Step 3: Add and verify domain
    # add_domain()
    list_domains
    
    # Step 4: Manage IPs and IP pools (before sending emails)
    list_ips
    create_ip_pool
    list_ip_pools
    
    # Step 5: Send emails (using the created IP pool)
    send_transactional_email
    send_marketing_email
    
    # Step 6: Monitor statistics
    get_sub_account_stats
    get_aggregate_stats
    
    # Step 7: Get account-level overview
    get_account_stats
    
    # Step 8: Retrieve message details (at the end to give system time to store data)
    # Add a small delay to ensure message data is stored
    puts "\n⏳ Waiting a few seconds for message data to be stored..."
    sleep(3)  # Wait 3 seconds
    get_message_details
    
    puts "\n╔═══════════════════════════════════════════════════════════════╗"
    puts '║   Workflow Complete!                                          ║'
    puts '╚═══════════════════════════════════════════════════════════════╝'
  end
end

def main
  example = ESPExample.new
  
  # Check if API keys are set
  if example.class::SUB_ACCOUNT_API_KEY == 'YOUR_SUB_ACCOUNT_API_KEY_HERE' ||
     example.class::ACCOUNT_API_KEY == 'YOUR_ACCOUNT_API_KEY_HERE'
    puts '⚠️  WARNING: Please set your API keys!'
    puts '   Set environment variables:'
    puts '   - SENDPOST_SUB_ACCOUNT_API_KEY'
    puts '   - SENDPOST_ACCOUNT_API_KEY'
    puts '   Or modify the constants in ESPExample.rb'
    puts
  end
  
  # Run the complete workflow
  example.run_complete_workflow
end

main if __FILE__ == $PROGRAM_NAME

