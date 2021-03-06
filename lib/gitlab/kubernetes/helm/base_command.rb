# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Helm
      class BaseCommand
        attr_reader :name, :files

        def initialize(rbac:, name:, files:, local_tiller_enabled:)
          @rbac = rbac
          @name = name
          @files = files
          @local_tiller_enabled = local_tiller_enabled
        end

        def rbac?
          @rbac
        end

        def local_tiller_enabled?
          @local_tiller_enabled
        end

        def pod_resource
          pod_service_account_name = rbac? ? service_account_name : nil

          Gitlab::Kubernetes::Helm::Pod.new(self, namespace, service_account_name: pod_service_account_name).generate
        end

        def generate_script
          <<~HEREDOC
            set -xeo pipefail
          HEREDOC
        end

        def pod_name
          "install-#{name}"
        end

        def config_map_resource
          Gitlab::Kubernetes::ConfigMap.new(name, files).generate
        end

        def service_account_resource
          return unless rbac?

          Gitlab::Kubernetes::ServiceAccount.new(service_account_name, namespace).generate
        end

        def cluster_role_binding_resource
          return unless rbac?

          subjects = [{ kind: 'ServiceAccount', name: service_account_name, namespace: namespace }]

          Gitlab::Kubernetes::ClusterRoleBinding.new(
            cluster_role_binding_name,
            cluster_role_name,
            subjects
          ).generate
        end

        def file_names
          files.keys
        end

        private

        def files_dir
          "/data/helm/#{name}/config"
        end

        def namespace
          Gitlab::Kubernetes::Helm::NAMESPACE
        end

        def service_account_name
          Gitlab::Kubernetes::Helm::SERVICE_ACCOUNT
        end

        def cluster_role_binding_name
          Gitlab::Kubernetes::Helm::CLUSTER_ROLE_BINDING
        end

        def cluster_role_name
          Gitlab::Kubernetes::Helm::CLUSTER_ROLE
        end
      end
    end
  end
end
