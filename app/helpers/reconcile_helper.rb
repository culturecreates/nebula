module ReconcileHelper
  def vite_asset_path(asset_name)
    manifest_path = Rails.root.join('public', 'batch-reconciliation-ui', '.vite','manifest.json')
   
    manifest = JSON.parse(File.read(manifest_path))
    puts "Manifest: #{manifest}"
    if asset_name == 'index.js'
      "/batch-reconciliation-ui/#{manifest.dig('index.html', 'file')}"
    elsif asset_name == 'index.css'
      "/batch-reconciliation-ui/#{manifest.dig('index.html', 'css').first}"
    end

  end
end
