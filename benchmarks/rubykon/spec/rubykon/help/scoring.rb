shared_examples_for "correctly scored" do |expected_score|
  it "gets the right score for black" do

    expect(black_score).to eq expected_score[:black]
  end

  it "gets the right score for white" do
    expect(white_score).to eq (expected_score[:white])
  end
end