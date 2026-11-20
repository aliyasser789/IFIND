"""Calculate student fees with discounts and penalties."""

BASE_FEE = 1000
SCHOLARSHIP_DISCOUNT = 0.20
LATE_PAYMENT_PENALTY = 100


def calculate_fee(scholarship, late_payment):
    """Calculate the final student fee."""
    fee = BASE_FEE

    if scholarship:
        fee -= fee * SCHOLARSHIP_DISCOUNT

    if late_payment:
        fee += LATE_PAYMENT_PENALTY

    return fee
