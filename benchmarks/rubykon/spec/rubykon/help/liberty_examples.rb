shared_examples_for "has liberties at position" do |x, y, expected|
  it "the group at #{x}-#{y} has #{expected} liberties" do
    identifier = board.identifier_for(x, y)
    expect(group_tracker.liberty_count_at(identifier)).to eq expected
  end
end