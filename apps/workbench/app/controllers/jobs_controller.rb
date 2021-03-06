class JobsController < ApplicationController

  def generate_provenance(jobs)
    nodes = []
    collections = []
    jobs.each do |j|
      nodes << j
      collections << j[:output]
      collections.concat(ProvenanceHelper::find_collections(j[:script_parameters]))
      nodes << {:uuid => j[:script_version]}
    end

    Collection.where(uuid: collections).each do |c|
      nodes << c
    end

    @svg = ProvenanceHelper::create_provenance_graph nodes, "provenance_svg", {:all_script_parameters => true, :script_version_nodes => true}
  end

  def index
    @svg = ""
    if params[:uuid]
      @jobs = Job.where(uuid: params[:uuid])
      generate_provenance(@jobs)
    else
      @jobs = Job.all
    end
  end

  def show
    generate_provenance([@object])
  end

  def index_pane_list
    if params[:uuid]
      %w(Recent Provenance)
    else
      %w(Recent)
    end
  end

  def show_pane_list
    %w(Attributes Provenance Metadata JSON API)
  end
end
