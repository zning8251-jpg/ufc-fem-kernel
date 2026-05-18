"""One-off smoke test for _fortran_strip_comments_and_strings."""
import arch_guardian as ag

f = ag._fortran_strip_comments_and_strings
assert f("status%message = 'RT: bridge pending'") == "status%message =  "
assert f("USE MD_ContPH_Brg, ONLY: x  ! populate bridge") == "USE MD_ContPH_Brg, ONLY: x  "
assert f("x = 'a''b' ! tail") == "x =   "
print("ok")
