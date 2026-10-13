test "weighted gpa can go above a 4.0 scale" {
    assert academics_error("3.85", "4.3", "4.0", "", "", "", "", "", "", "", "2027") == "";
    assert academics_error("3.85", "5.3", "4.0", "", "", "", "", "", "", "", "2027") == "Weighted GPA must be between 0 and 5.0.";
}

test "unweighted gpa stays within the scale" {
    assert academics_error("4.3", "", "4.0", "", "", "", "", "", "", "", "2027") == "Unweighted GPA must be between 0 and 4.0.";
}
