extends Resource
class_name PIDController

@export var kP : float = -0.7
@export var kI : float = -0.01
@export var kD : float = -0.3
@export var minIntegral = -10
@export var minCapIntegral = -10
var error = 0
var previousError = 0
var integralError = 0
var derivativeError = 0
@export var maxCapIntegral = 10
@export var maxIntegral = 10
var retError : float = 0

func _init(kP, kI, kD):
	self.kP = kP
	self.kI = kI
	self.kD = kD

func step():
	if previousError == null:
		previousError = error
	
	derivativeError = error - previousError
	integralError = integralError + error
	
	if minCapIntegral != null && minCapIntegral != null && integralError < minCapIntegral:
		integralError = minCapIntegral
	if maxCapIntegral != null && maxCapIntegral != null && integralError > maxCapIntegral:
		integralError = maxCapIntegral

	var mP = error * kP
	var mI = integralError * kI
	var mD = derivativeError * kD

	if minIntegral != null && minIntegral != null && mI < minIntegral:
		mI = minIntegral

	if maxIntegral != null && maxIntegral != null && mI > maxIntegral:
		mI = maxIntegral

	previousError = error
	retError = mP + mI + mD
	return retError

func getError():
	return retError
	
func setError(err: float):
	error = err

func reset():
	integralError = 0
