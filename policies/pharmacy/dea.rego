package pharmacy.dea

default allow = false

allow {
  input.prescriber.dea_valid
  input.pharmacy.dea_registered
  input.prescription.schedule != "I"
}
