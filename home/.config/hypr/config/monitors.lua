-- Secondary monitor: portrait (rotated 90° right), left of main.
hl.monitor({
  output    = "desc:Lenovo Group Limited R27qe UP331YNW",
  mode      = "2560x1440@144",
  position  = "0x0",
  scale     = 1,
  transform = 1,
})

-- Main monitor at its full 200Hz, right of the secondary.
hl.monitor({
  output   = "desc:Lenovo Group Limited R27qe Gen2 UTP03961",
  mode     = "2560x1440@200",
  position = "1440x800",
  scale    = 1,
})

-- Anything else falls back to auto.
hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = 1.0,
})
