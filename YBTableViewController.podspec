#
# Be sure to run `pod lib lint YBTableViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YBTableViewController'
  s.version          = '1.0.0'
  s.summary          = 'UITableViewController drop-in replacement with section header reordering.'
  s.description      = <<-DESC
This is a `UITableViewController` drop-in replacement that allows you to reorder section headers.
                       DESC

  s.homepage         = 'https://github.com/ynab/YBTableViewController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'You Need a Budget, LLC' => 'opensoure@youneedabudget.com' }
  s.source           = { :git => 'https://github.com/ynab/YBTableViewController.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ynab'

  s.ios.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'YBTableViewController/Classes/**/*'
  s.public_header_files = 'YBTableViewController/Classes/YBAnimationUtilities.h', 'YBTableViewController/Classes/YBTableViewController.h', 'YBTableViewController/Classes/YBTableViewHeaderFooterView.h'
  
  s.resource_bundles = {
    'YBTableViewController' => ['YBTableViewController/Assets/*.png']
  }

  s.frameworks = 'UIKit'
end
