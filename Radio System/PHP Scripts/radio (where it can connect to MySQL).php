<?php
$type = @$_GET["type"];
$params = @$_GET["params"];
if (!isset($type) || !isset($params)) exit;

$Radio = new CRadio();
if ($type == "add")
{
	$Radio->Add($params);
}
elseif ($type == "fail")
{
	$Radio->Fail($params);
}
elseif ($type == "exist")
{
	$Radio->Exist($params);
}
elseif ($type == "create")
{
	$Radio->Create($params);
}

class CRadio
{
	private $Connection = null;	
	
	public function __construct()
	{
		// If this is not running on the MySQL server box itself, use a remote IP here
		$this->Connection = new PDO("mysql:host=localhost;dbname=flow_gmod", "USERNAME", "PASSWORD");
		$this->Connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
	}
	
	public function Error($Str)
	{
		die($Str);
	}
	
	public function Success($Str)
	{
		echo $Str;
	}
	
	private function ParseParams($Params)
	{
		if ($Params == null)
			return null;
		
		$Explode = explode(";", $Params);
		if (!$Explode || count($Explode) == 0)
			return null;
		
		return $Explode;
	}
	
	private function GetTime($Input)
	{
		$dt = new DateTime("@$Input");
		return $dt->format('Y-m-d H:i:s');
	}
	
	private function Radio_SetStatus($Ticket, $Status, $Success)
	{
		$query = "UPDATE gmod_radio_queue SET szStatus = :status WHERE nTicket = :ticket AND szStatus = 'CREATE'";
		
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':ticket', $Ticket);
		$stmt->bindParam(':status', $Status);
		
		if ($stmt->execute())
			$this->Error($Success ? "S000: Added song successfully" : "E004: Couldn't add song to database");
		else
			$this->Error($Success ? "E006: Couldn't complete ticket status" : "E005: Couldn't set ticket status");
	}
	
	public function Add($Params)
	{
		$data = $this->ParseParams($Params);
		if (!$data || count($data) < 5)
			$this->Error("E002: Invalid parameters supplied!");
		
		if (!is_numeric($data[0]) || !is_numeric($data[1]) || !is_numeric($data[3])) $this->Error("E003: Invalid parameter");
		
		$artist = "";
		if (count($data) > 5 && $data[5] != null && $data[5] != "")
			$artist = $data[5];
		
		$query = "INSERT INTO gmod_radio (szUnique, nService, nTicket, szDate, nDuration, szTagTitle, szTagArtist) VALUES (:unique, :service, :ticket, :date, :duration, :title, :artist)";
		
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':unique', $data[2]);
		$stmt->bindParam(':service', $data[0]);
		$stmt->bindParam(':ticket', $data[1]);
		$stmt->bindParam(':date', $this->GetTime(time()));
		$stmt->bindParam(':duration', $data[3]);
		$stmt->bindParam(':title', $data[4]);
		$stmt->bindParam(':artist', $artist);
		
		if ($stmt->execute())
			$this->Radio_SetStatus($data[1], "DONE", true);
		else
			$this->Radio_SetStatus($data[1], "FAIL_0", false);
	}
	
	public function Fail($Params)
	{
		$data = $this->ParseParams($Params);
		if (!$data || count($data) != 1)
			$this->Error("E002: Invalid parameters supplied!");
		
		if (!is_numeric($data[0])) $this->Error("E003: Invalid parameter");
		
		$query = "UPDATE gmod_radio_queue SET szStatus = :status WHERE nTicket = :ticket AND szStatus = 'CREATE'";
		$status = "FAIL_1";
		
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':ticket', $data[0]);
		$stmt->bindParam(':status', $status);
		
		if ($stmt->execute())
			$this->Error("E007: Failed to convert");
		else
			$this->Error("E008: Failed to set status of failed ticket");
	}
	
	public function Exist($Params)
	{
		$data = $this->ParseParams($Params);
		if (!$data || count($data) != 2)
			$this->Error("E002: Invalid parameters supplied!");
		
		if (!is_numeric($data[0])) $this->Error("E003: Invalid parameter");
		
		$query = "SELECT * FROM gmod_radio WHERE nService = :service AND szUnique = :unique LIMIT 1";
		$stmt = $this->Connection->prepare($query);
		$stmt->bindValue('service', $data[0]);
		$stmt->bindValue('unique', $data[1]);
		$stmt->execute();
		$result = $stmt->fetchAll();
				
		if (count($result) > 0)
		{
			foreach ($result as $row)
			{
				$this->Success($row["szUnique"] . ';' . $row["nService"] . ';' . $row["nDuration"] . ';' . $row["szTagTitle"] . ';' . $row["szTagArtist"]);
				break;
			}
		}
		else
			$this->Error("FREE");
	}
	
	public function Create($Params)
	{
		$data = $this->ParseParams($Params);
		if (!$data || count($data) != 1)
			$this->Error("E002: Invalid parameters supplied!");
		
		if (!is_numeric($data[0])) $this->Error("E003: Invalid parameter");
		
		$query = "INSERT INTO gmod_radio_queue (nTicket, szDate, szStatus) VALUES (:ticket, :created, 'CREATE')";
		
		$stmt = $this->Connection->prepare($query);
		$stmt->bindParam(':ticket', $data[0]);
		$stmt->bindParam(':created', time());
		
		if ($stmt->execute())
			$this->Success("YES");
		else
			$this->Error("NO");
	}
}
?>