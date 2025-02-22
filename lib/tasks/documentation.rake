# frozen_string_literal: true
require 'webrick'

namespace :docs do
  desc 'Generate GraphQL schema'
  task :schema => :environment do
    puts 'Generating GraphQL schema...'
    schema_path = Rails.root.join('schema.graphql')
    File.write(schema_path, N8nWorkerSchema.to_definition)
    puts "Schema written to #{schema_path}"
  end

  desc 'Generate all documentation (YARD and GraphQL)'
  task :generate => [:schema] do
    puts 'Generating YARD documentation...'
    yard_stats = `yard stats --list-undoc`
    system 'yard doc'

    puts 'Generating GraphQL documentation...'
    config = {
      schema: File.read(Rails.root.join('schema.graphql')),
      output_dir: Rails.root.join('documentation/graphql').to_s,
      base_url: '',
      delete_output: true,
      classes: {
        code: 'prettyprint',
        type: 'type-doc'
      }
    }
    GraphQLDocs.build(config)

    puts "\nDocumentation générée !"
    puts "\nStatistiques YARD :"
    puts yard_stats.lines.first(6)
    puts "\nPour voir la documentation :"
    puts "  rake docs:serve"
  end

  desc 'Servir toute la documentation'
  task :serve => :environment do
    # Obtenir l'adresse IP de WSL
    wsl_ip = `ip addr show eth0 | grep "inet\\b" | awk '{print $2}' | cut -d/ -f1`.strip

    # Stocker les PIDs pour pouvoir arrêter les serveurs
    pid_file = Rails.root.join('tmp/docs_servers.pid')
    
    # Lancer YARD dans un processus séparé
    yard_pid = Process.spawn('yard server --host 0.0.0.0 --port 8808')
    
    # Lancer WEBrick dans un thread
    webrick_thread = Thread.new do
      doc_root = Rails.root.join('documentation/graphql')
      server = WEBrick::HTTPServer.new(
        Host: '0.0.0.0',
        Port: 8809,
        DocumentRoot: doc_root,
        AccessLog: [],
        Logger: WEBrick::Log.new(File::NULL),
        MimeTypes: WEBrick::HTTPUtils::DefaultMimeTypes.merge({
          'css'  => 'text/css',
          'js'   => 'application/javascript',
          'png'  => 'image/png',
          'jpg'  => 'image/jpeg',
          'jpeg' => 'image/jpeg',
          'gif'  => 'image/gif',
          'svg'  => 'image/svg+xml'
        })
      )

      # Servir les fichiers statiques et gérer les routes SPA
      server.mount_proc('/') do |req, res|
        # Nettoyer le chemin de la requête
        request_path = req.path.gsub(/^\/+/, '')
        file_path = File.join(doc_root, request_path)

        # Gérer les cas spéciaux
        if request_path.empty? || request_path == 'index.html'
          file_path = File.join(doc_root, 'index.html')
        elsif !File.exist?(file_path) || File.directory?(file_path)
          # Essayer avec .html
          html_path = "#{file_path}.html"
          if File.exist?(html_path)
            file_path = html_path
          else
            # Essayer dans un sous-dossier
            possible_paths = [
              File.join(doc_root, request_path, 'index.html'),
              File.join(doc_root, 'object', "#{request_path}.html"),
              File.join(doc_root, 'mutation', "#{request_path}.html"),
              File.join(doc_root, 'query', "#{request_path}.html"),
              File.join(doc_root, 'input_object', "#{request_path}.html"),
              File.join(doc_root, 'enum', "#{request_path}.html"),
              File.join(doc_root, 'scalar', "#{request_path}.html"),
              File.join(doc_root, 'union', "#{request_path}.html"),
              File.join(doc_root, 'interface', "#{request_path}.html")
            ]
            
            file_path = possible_paths.find { |p| File.exist?(p) } || File.join(doc_root, 'index.html')
          end
        end

        # Servir le fichier
        res.body = File.read(file_path)
        res.content_type = server.config[:MimeTypes][File.extname(file_path).delete('.')] || 'text/html'
      end
      
      trap('INT') { server.shutdown }
      server.start
    end

    # Sauvegarder les PIDs
    File.write(pid_file, "#{yard_pid}\n#{Process.pid}")

    puts "\nDocumentation disponible sur :"
    puts "  Local:"
    puts "    YARD: http://localhost:8808"
    puts "    GraphQL: http://localhost:8809"
    puts "  Depuis Windows:"
    puts "    YARD: http://#{wsl_ip}:8808"
    puts "    GraphQL: http://#{wsl_ip}:8809"
    puts "\nPour arrêter les serveurs :"
    puts "  Ctrl+C ou 'rake docs:stop' dans un autre terminal"

    # Attendre le thread WEBrick
    webrick_thread.join
  rescue Interrupt
    cleanup_servers
  end

  desc 'Arrêter les serveurs de documentation'
  task :stop => :environment do
    cleanup_servers
  end

  private

  def cleanup_servers
    pid_file = Rails.root.join('tmp/docs_servers.pid')
    if File.exist?(pid_file)
      pids = File.readlines(pid_file).map(&:strip)
      pids.each do |pid|
        begin
          Process.kill('INT', pid.to_i)
          puts "Arrêt du serveur PID: #{pid}"
        rescue Errno::ESRCH
          # Le processus n'existe plus
        end
      end
      File.delete(pid_file)
      puts "Serveurs de documentation arrêtés"
    else
      puts "Aucun serveur de documentation en cours d'exécution"
    end
  end
end 