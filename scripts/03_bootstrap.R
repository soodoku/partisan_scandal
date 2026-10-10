d <- read.csv("data/derived/main.csv")
fit <- lm(gap ~ post + relative_month + factor(id), data = d)
set.seed(20261010)
dqrng::dqset.seed(20261010)
boot <- fwildclusterboot::boottest(fit,
  param = "post", B = 9999, clustid = "statecode", bootcluster = "statecode",
  type = "rademacher", impose_null = TRUE, conf_int = FALSE,
  bootstrap_type = "fnw11", sampling = "standard", engine = "R", nthreads = 1
)
valid <- sum(is.finite(boot$t_boot))
exceedances <- sum(abs(boot$t_boot) >= abs(boot$t_stat), na.rm = TRUE)
stopifnot(valid == boot$boot_iter)
write.csv(data.frame(
  seed = 20261010, draws = valid, exceedances = exceedances,
  p = (exceedances + 1) / (valid + 1),
  p_directional = (sum(boot$t_boot >= boot$t_stat, na.rm = TRUE) + 1) / (valid + 1),
  statistic = boot$t_stat,
  null_imposed = TRUE, method = "WCR11", weights = "Rademacher", cluster = "state"
), "tabs/bootstrap.csv", row.names = FALSE)
