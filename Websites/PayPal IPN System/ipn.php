<?php
if (count($_POST) == 0)
	die("__INVALID__");

$CIPN = new CIPN();
	
// Obtain posted variables
$req = 'cmd=_notify-validate';
foreach ($_POST as $key => $value)
{
	$value = urlencode(stripslashes($value));
	$req .= "&$key=$value";
}
// Set headers
$header = "POST /cgi-bin/webscr HTTP/1.0\r\n";
$header .= "Content-Type: application/x-www-form-urlencoded\r\n";
$header .= "Content-Length: " . strlen($req) . "\r\n\r\n";

// Open a socket to PayPal to receive information
$fp = fsockopen('www.paypal.com', 80, $errno, $errstr, 30);
if (!$fp)
{
	// Optional Logging (Currently Disabled)
}
else
{
	fputs ($fp, $header . $req);
	while (!feof($fp))
	{
		// Get data
		$res = fgets ($fp, 1024);
		if (strcmp ($res, "VERIFIED") == 0)
		{
			// Variables
			$Status = $_POST['payment_status'];
			$Name = array('First' => $_POST['first_name'], 'Last' => $_POST['last_name']);
			$Email = $_POST['payer_email'];
			$Country = $_POST['residence_country'];
			$Amount = $_POST['mc_gross'];
			$Field = $_POST['custom'];
			$IPNSandbox = @$_POST['test_ipn'];
			if ($IPNSandbox == "1")
			{
				$CIPN->GeneralLog("IPN Sandbox attempt: " . $_SERVER["REMOTE_ADDR"]);
				die("__INVALID__");
			}
			
			$CIPN->ProcessDonation($Name['First'], $Name['Last'], $Email, $Country, $Amount, $Field, $Status);
		}
		else if (strcmp ($res, "INVALID") == 0)
		{
			// Variables
			$Status = $_POST['payment_status'];
			$Name = array('First' => $_POST['first_name'], 'Last' => $_POST['last_name']);
			$Email = $_POST['payer_email'];
			$Country = $_POST['residence_country'];
			$Amount = $_POST['mc_gross'];
			$Field = $_POST['custom'];
			$IPNSandbox = @$_POST['test_ipn'];
			if ($IPNSandbox == "1")
			{
				$CIPN->GeneralLog("IPN Sandbox attempt: " . $_SERVER["REMOTE_ADDR"]);
				die("__INVALID__");
			}
			
			$CIPN->ProcessDonation($Name['First'], $Name['Last'], $Email, $Country, $Amount, $Field, $Status);
		}
	}
	fclose ($fp);
}

class CIPN
{
	private $Connection = null;	
	
	public function __construct()
	{
		// Make sure this is edited and set to a working database instance
		// Change any SQL queries in "AddLog", "SetReward", "GetVIPLevel" or "GeneralLog"
		
		$this->Connection = new PDO("mysql:host=localhost;dbname=flow_gmod", "USERNAME", "PASSWORD");
		$this->Connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
	}
	
	public function ProcessDonation($First, $Last, $Email, $Country, $Amount, $Steam, $Status)
	{
		if ($Status == "Completed")
		{
			$this->AddDonation($First . ' ' . $Last, $Email, $Country, $Amount, $Steam);
		}
		else
		{
			$this->AddLog($First . ' ' . $Last, $Email, $Country, $Amount, $Steam, $Status);
		}
		
		$this->GeneralLog("Processed a donation from: " . $Email . " - " . $Steam);
	}
	
	private function AddDonation($Name, $Email, $Country, $Amount, $Steam)
	{
		$this->SetReward($Steam, $Amount);
		$this->AddLog($Name, $Email, $Country, $Amount, $Steam, "Success");
	}
	
	private function AddLog($Name, $Email, $Country, $Amount, $Steam, $Status)
	{	
		$query = "INSERT INTO gmod_donations (szEmail, szName, szCountry, nAmount, szSteam, szDate, szStatus) VALUES (:email, :name, :country, :amount, :steam, :date, :status)";
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':email', $Email);
		$stmt->bindParam(':name', $Name);
		$stmt->bindParam(':country', $Country);
		$stmt->bindParam(':amount', $Amount);
		$stmt->bindParam(':steam', $Steam);
		$stmt->bindParam(':date', $this->GetTime(time()));
		$stmt->bindParam(':status', $Status);
		
		if (!$stmt->execute())
			echo '_ERROR_';
	}
	
	private function GetTime($Input)
	{
		$dt = new DateTime("@$Input");
		return $dt->format('Y-m-d H:i:s');
	}
	
	private function SetReward($Steam, $Amount)
	{
		$Type = 1;
		$Month = 40320;
		$Length = $Month;
		$Amount = round($Amount);
		
		switch ($Amount)
		{
			case 5: $Type = 1; $Length = 1 * $Month; break;
			case 9: $Type = 1; $Length = 2 * $Month; break;
			case 14: $Type = 1; $Length = 3 * $Month; break;
			case 18: $Type = 1; $Length = 4 * $Month; break;
			case 24: $Type = 1; $Length = 6 * $Month; break;
			case 32: $Type = 1; $Length = 8 * $Month; break;
			case 35: $Type = 1; $Length = 10 * $Month; break;
			case 42: $Type = 1; $Length = 12 * $Month; break;
			case 10: $Type = 2; $Length = 1 * $Month; break;
			case 19: $Type = 2; $Length = 2 * $Month; break;
			case 27: $Type = 2; $Length = 3 * $Month; break;
			case 36: $Type = 2; $Length = 4 * $Month; break;
			case 48: $Type = 2; $Length = 6 * $Month; break;
			case 64: $Type = 2; $Length = 8 * $Month; break;
			case 70: $Type = 2; $Length = 10 * $Month; break;
			case 84: $Type = 2; $Length = 12 * $Month; break;
			case 100: $Type = 2; $Length = 0; break;
			case 150: $Type = 2; $Length = 0; break;
			case 200: $Type = 2; $Length = 0; break;
			default: $Type = 1; $Length = $Month / 4; break;
		}
		
		if (substr($Steam, 0, 7) != 'STEAM_0') die("_ERROR_");
		
		$query = "";
		$VIP = $this->GetVIPLevel($Steam);
		if (!$VIP)
			$query = "INSERT INTO gmod_vips (szSteam, nType, szTag, szName, szChat, nStart, nLength) VALUES (:steam, :type, '', '', '', :start, :length)";
		else
			$query = "UPDATE gmod_vips SET nType = :type, nLength = :length, nStart = :start WHERE szSteam = :steam";
		
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':steam', $Steam);
		$stmt->bindParam(':type', $Type);
		$stmt->bindParam(':length', $Length);
		$stmt->bindParam(':start', time());
			
		if ($stmt->execute())
			echo "";
		else
			echo "_ERROR_";
	}
	
	private function GetVIPLevel($Steam)
	{
		$query = "SELECT * FROM gmod_vips WHERE szSteam = :steam ORDER BY nID DESC LIMIT 1";
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':steam', $Steam);
		$stmt->execute();
		$result = $stmt->fetch(PDO::FETCH_ASSOC);
		
		if ($result)
			return true;
		else
			return false;
	}
	
	public function GeneralLog($Text)
	{
		$query = "INSERT INTO gmod_logging (nType, szData, szDate, szAdminSteam, szAdminName) VALUES (0, :text, :time, 'STEAM_0_IPN', 'IPNLog')";
			
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':text', $Text);
		$stmt->bindParam(':time', $this->GetTime(time()));
				
		if ($stmt->execute())
			echo "";
		else
			echo "_ERROR_";
	}
}
?>