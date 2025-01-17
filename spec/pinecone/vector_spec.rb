require 'spec_helper'

RSpec.describe Pinecone::Vector do
  let(:index) { 
    VCR.use_cassette("use_index") do
      Pinecone::Vector.new("example-index") 
    end
  }

  describe "#upsert", :vcr do
    let(:data) { { vectors: [{ values: [1, 2, 3], id: "1" }] } }
    let(:response) {
      index.upsert(data)
    }      

    describe "successful response" do
      let(:response) {
        index.upsert(data)
      }  
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to eq({"upsertedCount"=>1})
      end
    end

    describe "unsuccessful response" do
      let(:response) {
        index.upsert("foo")
      } 
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(400)
        expect(response.parsed_response).to eq(": Root element must be a message.")
      end
    end
  end

  describe "#delete", :vcr do
    let(:data) { { vectors: [{ values: [1, 2, 3], id: "5" }] } }

    describe "successful response" do
      let(:response) {
        index.delete(ids: ["5"])
      }

      it "returns a response" do
        index.upsert(data)
        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
      end
    end
  end

  describe "#fetch", :vcr do
    describe "successful response" do
      let(:response) {
        index.fetch(ids: ["1", "2"])
      }

      it "returns a response" do
        index.upsert({ vectors: [{ values: [1, 2, 3], id: "1" }] })
        index.upsert({ vectors: [{ values: [1, 2, 3], id: "2" }] })

        expect(response).to be_a(HTTParty::Response)
        expect(response.code).to eq(200)
        expect(response.parsed_response).to eq({
          "namespace" => "",
          "vectors" => {
            "1" => {
              "id" => "1",
              "values" => [1, 2, 3]
            },
            "2" => {
              "id" => "2",
              "values" => [1, 2, 3]
            }
          }
        })
      end
    end
  end

  describe "#query", :vcr do
    let(:data) { { 
      vectors: [
        { values: [1, 2, 3], id: "1" },
        { values: [0, 1, -1], id: "2" },
        { values: [1, -1, 0], id: "3" }
      ] 
    } }
    let(:query_vector) { [0.5, -0.5, 0] }     

    describe "successful response" do
      before do
        index.upsert(data)
      end

      let(:response) {
        index.query(vector: query_vector)
      } 
  
      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({
              "results" => [],
              "matches" => [
                {
                        "id" => "3",
                    "score" => 1,
                    "values" => []
                },
                {
                        "id" => "2",
                    "score" => -0.5,
                    "values" => []
                },
                {
                        "id" => "1",
                    "score" => -0.5,
                    "values" => []
                }
            ],
            "namespace" => ""
        })
      end
    end

    describe "with namespace" do
      before do
        index.upsert(data.merge(namespace: "example-namespace"))
      end

      let(:response) {
        index.query(namespace: "example-namespace", vector: query_vector)
      }

      it "returns a response" do
        expect(response).to be_a(HTTParty::Response)
        expect(response.parsed_response).to eq({
          "results" => [],
          "matches" => [
            {
                    "id" => "3",
                "score" => 1,
                "values" => []
            },
            {
                    "id" => "2",
                "score" => -0.5,
                "values" => []
            },
            {
                    "id" => "1",
                "score" => -0.5,
                "values" => []
            }
        ],
          "namespace" => "example-namespace"
        })
      end
    end

    describe "missing index" do
      it "raises an exception" do
        VCR.use_cassette("missing_index") do
          expect { Pinecone::Vector.new("missing-index") }.to raise_error(Pinecone::IndexNotFoundError)
        end
      end
    end
  end

end